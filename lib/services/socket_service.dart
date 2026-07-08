import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_config.dart';
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
  final Set<int> _joinedRoutes = {};

  Stream<AttendanceEvent> get events => _controller.stream;

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
      // Re-join rooms after reconnects — server room membership is
      // per-connection.
      for (final id in _joinedRoutes) {
        socket.emit(SocketEvent.join, id);
      }
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
    socket.on(SocketEvent.updated, (data) {
      if (data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      _controller.add(AttendanceEvent(
        type: AttendanceEventType.studentUpdated,
        attendanceId: map['attendanceid'] as int?,
        newStatus: map['new_status'] as String?,
        phase: map['phase'] as String?,
      ));
    });

    _socket = socket;
  }

  void _emitRoster(AttendanceEventType type, dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final students = (map['students'] as List? ?? [])
        .map((e) =>
            AttendanceStudent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _controller.add(AttendanceEvent(
      type: type,
      routeId: map['routeid'] as int?,
      students: students,
    ));
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
    _joinedRoutes.clear();
    _socket?.dispose();
    _socket = null;
  }
}
