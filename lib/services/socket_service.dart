import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_config.dart';
import 'auth_service.dart';
import 'attendance_service.dart';
import 'auth_session.dart';

/// Socket event names — mirrors backend utils/enum.js SOCKET_EVENT.
class SocketEvent {
  static const String join = 'route:join';
  static const String leave = 'route:leave';
  static const String morningStarted = 'attendance:morning_started';
  static const String updated = 'attendance:updated';
  static const String morningCompleted = 'route:morning_completed';
  static const String afternoonStarted = 'attendance:afternoon_started';
  static const String afternoonCompleted = 'route:afternoon_completed';

  /// Driver -> server. The server re-broadcasts it to the route room as
  /// [busLocation], which this app never listens to: parents deliberately
  /// have no map.
  static const String driverLocation = 'driver:location';

  /// Server -> the route room, after a driver ping is placed on the line.
  static const String etaUpdated = 'eta:updated';

  /// Server -> the socket that asked, when a request is refused.
  static const String roomError = 'route:error';
}

/// When the bus is expected at one student's stop.
///
/// In the morning that stop is the pickup point; in the afternoon it is the
/// same waypoint used as the drop-off, so the same number means "bus gets
/// here" or "child gets home" depending on the phase.
class StopEta {
  final int studentId;
  final int? attendanceId;
  final int metersAway;

  /// Absolute arrival time, not a countdown.
  ///
  /// The server also sends `seconds_away`, but that is only true at the
  /// instant it was generated. Holding the absolute time lets the UI keep
  /// counting down correctly between pings, and go stale honestly when the
  /// driver's phone stops reporting.
  final DateTime eta;

  const StopEta({
    required this.studentId,
    this.attendanceId,
    required this.metersAway,
    required this.eta,
  });

  factory StopEta.fromJson(Map<String, dynamic> json) {
    return StopEta(
      studentId: json['studentid'] as int,
      attendanceId: json['attendanceid'] as int?,
      metersAway: (json['meters_away'] as num?)?.round() ?? 0,
      eta: DateTime.parse(json['eta'] as String).toLocal(),
    );
  }
}

/// One `eta:updated` broadcast: every stop the bus has yet to reach.
///
/// Students already picked up (morning) or dropped off / absent are filtered
/// out by the server, so a student missing from [stops] simply has no wait
/// left to report.
class RouteEta {
  final int routeId;
  final String phase;
  final DateTime generatedAt;

  /// The server's own read on whether this estimate is trustworthy — set when
  /// the bus is crawling relative to plan, or its fixes are landing far from
  /// the route line. The UI shows a softer number rather than hiding it.
  final bool lowConfidence;

  final Map<int, StopEta> byStudent;

  const RouteEta({
    required this.routeId,
    required this.phase,
    required this.generatedAt,
    required this.lowConfidence,
    required this.byStudent,
  });

  factory RouteEta.fromJson(Map<String, dynamic> json) {
    final stops = <int, StopEta>{};
    for (final raw in (json['stops'] as List? ?? const [])) {
      final stop = StopEta.fromJson(Map<String, dynamic>.from(raw as Map));
      stops[stop.studentId] = stop;
    }
    return RouteEta(
      routeId: json['routeid'] as int,
      phase: (json['phase'] ?? '') as String,
      generatedAt: DateTime.parse(json['generated_at'] as String).toLocal(),
      lowConfidence: json['confidence'] == 'low',
      byStudent: stops,
    );
  }
}

enum AttendanceEventType {
  morningStarted,
  afternoonStarted,
  studentUpdated,
  morningCompleted,
  afternoonCompleted,
}

/// One live update pushed by the backend to the `route:<id>` room.
class AttendanceEvent {
  final AttendanceEventType type;
  final int? routeId;

  /// Set on started/completed events (full roster).
  final List<AttendanceStudent> students;

  /// Set on studentUpdated events.
  final int? attendanceId;
  final String? newStatus;
  final String? phase;

  const AttendanceEvent({
    required this.type,
    this.routeId,
    this.students = const [],
    this.attendanceId,
    this.newStatus,
    this.phase,
  });
}

/// Singleton socket.io connection authenticated with the session's
/// access token (backend reads socket.handshake.auth.token).
///
/// Consumers join route rooms and listen on [events]; the connection is
/// shared so parent widgets watching several routes reuse one socket.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  final _controller = StreamController<AttendanceEvent>.broadcast();
  final _etaController = StreamController<RouteEta>.broadcast();
  final Set<int> _joinedRoutes = {};
  bool _recovering = false;

  /// Whether the live feed is currently up. UI can watch this to tell the
  /// user their status may be stale.
  final ValueNotifier<bool> connected = ValueNotifier(false);

  /// Last transport/handshake error, for diagnostics.
  final ValueNotifier<String?> lastError = ValueNotifier(null);

  Stream<AttendanceEvent> get events => _controller.stream;

  /// Arrival estimates for the route rooms this socket has joined. Emitted on
  /// every driver position ping, so several times a minute during a run.
  Stream<RouteEta> get etaEvents => _etaController.stream;

  /// Whether a connect error came from the server refusing the handshake
  /// rather than the connection failing to happen at all.
  ///
  /// The backend's socket middleware rejects with specific text
  /// (`Authentication required`, `User not found`, `Session terminated…`, or
  /// a jwt error); socket.io's own transport failures read `timeout`,
  /// `xhr poll error`, `websocket error`. Only the former is fixable by
  /// refreshing a token.
  @visibleForTesting
  static bool debugIsAuthRejection(Object? err) => _isAuthRejection(err);

  static bool _isAuthRejection(Object? err) {
    final text = err.toString().toLowerCase();
    const transport = ['timeout', 'xhr poll error', 'websocket error'];
    if (transport.any(text.contains)) return false;
    const auth = ['auth', 'token', 'session', 'jwt', 'user not found'];
    return auth.any(text.contains);
  }

  /// A rejected handshake is usually an expired access token. Refresh once
  /// and rebuild the socket; the guard stops a refresh/retry loop when the
  /// failure is really the server being unreachable.
  Future<void> _recoverAuth() async {
    if (_recovering) return;
    _recovering = true;
    try {
      await AuthService.refresh();
      final routes = Set<int>.from(_joinedRoutes);
      disconnect();
      for (final id in routes) {
        joinRoute(id);
      }
    } catch (_) {
      // Leave `connected` false; the session is genuinely gone.
    } finally {
      _recovering = false;
    }
  }

  void connect() {
    if (_socket != null) return;
    final token = AuthSession.instance.accessToken;
    if (token == null) return;

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .build(),
    );

    socket.onConnect((_) {
      connected.value = true;
      lastError.value = null;
      if (kDebugMode) debugPrint('[socket] connected to ${ApiConfig.baseUrl}');
      // Re-join rooms after reconnects — server room membership is
      // per-connection.
      for (final id in _joinedRoutes) {
        socket.emit(SocketEvent.join, id);
      }
    });

    socket.onDisconnect((reason) {
      connected.value = false;
      if (kDebugMode) debugPrint('[socket] disconnected: $reason');
    });

    // Without these the live feed can die in total silence: the UI keeps
    // showing the last known status with no indication it is now stale.
    socket.onConnectError((err) {
      connected.value = false;
      lastError.value = err.toString();
      if (kDebugMode) debugPrint('[socket] connect error: $err');
      // Only a rejected handshake is worth refreshing for. A transport
      // failure — timeout, DNS, a tunnel dropping — is not an auth problem,
      // and refreshing on every one both hammers /auth/refresh and rotates
      // the refresh token on a schedule set by the user's signal strength.
      // socket.io's own reconnection handles those.
      if (_isAuthRejection(err)) _recoverAuth();
    });
    socket.onError((err) {
      lastError.value = err.toString();
    });

    // The handshake token is a 15-minute access token. socket.io replays the
    // ORIGINAL auth payload on every reconnect, so once it expires the socket
    // can never re-establish. Refresh the auth map before each attempt.
    socket.io.on('reconnect_attempt', (_) {
      final token = AuthSession.instance.accessToken;
      if (token != null) socket.auth = {'token': token};
    });

    socket.on(SocketEvent.morningStarted, (data) {
      _emitRoster(AttendanceEventType.morningStarted, data);
    });
    socket.on(SocketEvent.afternoonStarted, (data) {
      _emitRoster(AttendanceEventType.afternoonStarted, data);
    });
    socket.on(SocketEvent.morningCompleted, (data) {
      _emitRoster(AttendanceEventType.morningCompleted, data);
    });
    socket.on(SocketEvent.afternoonCompleted, (data) {
      _emitRoster(AttendanceEventType.afternoonCompleted, data);
    });
    // A refused room join is the difference between "the run has not started"
    // and "you are not allowed to watch this route", and without this the two
    // look identical: an empty screen.
    socket.on(SocketEvent.roomError, (data) {
      final message = data is Map
          ? (data['message'] ?? data.toString()).toString()
          : data.toString();
      lastError.value = message;
      if (kDebugMode) debugPrint('[socket] route:error $message');
    });

    socket.on(SocketEvent.etaUpdated, (data) {
      if (data is! Map) return;
      try {
        _etaController.add(RouteEta.fromJson(Map<String, dynamic>.from(data)));
      } catch (_) {
        // A malformed estimate is not worth tearing the socket down for; the
        // next ping is seconds away and the UI just keeps the previous one
        // until it ages out.
      }
    });

    socket.on(SocketEvent.updated, (data) {
      if (data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      _controller.add(
        AttendanceEvent(
          type: AttendanceEventType.studentUpdated,
          attendanceId: map['attendanceid'] as int?,
          newStatus: map['new_status'] as String?,
          phase: map['phase'] as String?,
        ),
      );
    });

    _socket = socket;
  }

  void _emitRoster(AttendanceEventType type, dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final students = (map['students'] as List? ?? [])
        .map(
          (e) =>
              AttendanceStudent.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    _controller.add(
      AttendanceEvent(
        type: type,
        routeId: map['routeid'] as int?,
        students: students,
      ),
    );
  }

  /// Reports the bus's position for an in-progress run.
  ///
  /// The server refuses anything that is not a driver on their own route
  /// with a run IN_PROGRESS, and answers on the ack with
  /// `{ok: false, status, message}`; [onRefused] receives that message so a
  /// failure is not swallowed. `{ok: true, stale: true}` means the upsert
  /// guard dropped an out-of-order fix, which is expected and not an error —
  /// [onStale] exists so diagnostics can tell "dropped by the guard" apart
  /// from "stored", which look identical from the client otherwise.
  /// How long to wait for the server to answer a position report.
  ///
  /// socket.io buffers an emit on a disconnected socket forever and never
  /// calls the ack, so without this a driver whose connection has died sees a
  /// perfectly normal screen while nothing reaches the server.
  static const Duration _ackTimeout = Duration(seconds: 12);

  void emitDriverLocation(
    Map<String, dynamic> payload, {
    void Function(String message)? onRefused,
    void Function()? onStale,
    void Function()? onStored,
    void Function()? onTimeout,
  }) {
    connect();
    final socket = _socket;
    if (socket == null) {
      // No session, so nothing can be reported. Treated as a timeout: the
      // caller's job is the same either way — tell the driver.
      onTimeout?.call();
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[socket] emitting driver:location connected=${socket.connected}',
      );
    }

    var answered = false;
    final timer = Timer(_ackTimeout, () {
      if (answered) return;
      answered = true;
      if (kDebugMode) debugPrint('[socket] driver:location not acknowledged');
      onTimeout?.call();
    });

    socket.emitWithAck(
      SocketEvent.driverLocation,
      payload,
      ack: (dynamic response) {
        if (answered) return;
        answered = true;
        timer.cancel();

        // Anything that is not the documented envelope is still an answer,
        // but not one we can classify. Report it rather than returning: the
        // caller is counting unanswered reports to decide when the socket is
        // dead, and a silent return leaves that counter frozen — the
        // connection could never be rebuilt and the driver would never be
        // told they had stopped being tracked.
        if (response is! Map) {
          onRefused?.call('Malformed acknowledgement');
          return;
        }
        if (response['ok'] == true) {
          if (response['stale'] == true) {
            onStale?.call();
          } else {
            onStored?.call();
          }
          return;
        }
        final message = (response['message'] ?? 'Location rejected').toString();
        onRefused?.call(message);
      },
    );
  }

  /// Tears the connection down and builds a fresh one, preserving rooms.
  ///
  /// For when the socket claims to be up but the server has stopped
  /// answering — socket.io's own reconnection only fires on a transport it
  /// knows has dropped.
  void rebuild() {
    final routes = Set<int>.from(_joinedRoutes);
    disconnect();
    connect();
    for (final id in routes) {
      joinRoute(id);
    }
  }

  void joinRoute(int routeId) {
    connect();
    _joinedRoutes.add(routeId);
    _socket?.emit(SocketEvent.join, routeId);
  }

  void leaveRoute(int routeId) {
    _joinedRoutes.remove(routeId);
    _socket?.emit(SocketEvent.leave, routeId);
  }

  /// Tears down the connection (e.g. on logout).
  void disconnect() {
    connected.value = false;
    _joinedRoutes.clear();
    _socket?.dispose();
    _socket = null;
  }
}
