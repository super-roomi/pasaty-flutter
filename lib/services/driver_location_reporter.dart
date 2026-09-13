import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mockup/Util/debug_log.dart';
import 'package:geolocator/geolocator.dart';

import 'location_stream.dart';
import 'socket_service.dart';

/// A snapshot of what the reporter is actually doing.
///
/// Exists because on-device logging is not always reachable — a cable drops,
/// the VM service refuses to attach, mDNS is blocked. These counters sit on
/// paths that already run, so they cost nothing, and the driver screen can
/// render them when built with `--dart-define=DIAG=true`.
class ReporterDiagnostics {
  final bool subscribed;
  final bool? serviceEnabled;
  final String? permission;

  /// iOS 14+ Precise Location. `reduced` means every fix arrives hundreds of
  /// metres wide and is dropped by the accuracy gate, so the run reports
  /// nothing at all.
  final String? accuracy;

  /// Fixes handed over by the OS, before any filtering.
  final int fixes;

  /// Fixes discarded for poor accuracy.
  final int dropped;

  /// Fixes discarded because they arrived inside the pacing interval.
  final int throttled;

  /// Payloads handed to the socket.
  final int sent;

  /// Payloads the server answered.
  final int acked;

  final DateTime? lastFixAt;
  final DateTime? lastSentAt;
  final double? lastAccuracy;
  final String? lastError;

  const ReporterDiagnostics({
    this.subscribed = false,
    this.serviceEnabled,
    this.permission,
    this.accuracy,
    this.fixes = 0,
    this.dropped = 0,
    this.throttled = 0,
    this.sent = 0,
    this.acked = 0,
    this.lastFixAt,
    this.lastSentAt,
    this.lastAccuracy,
    this.lastError,
  });
}

/// Streams the bus's position to the backend while a run is under way.
///
/// Deliberately separate from the route map: the map's GPS stream only runs
/// while the driver has the map open, but position reporting has to continue
/// for the whole run whether or not anyone is looking at it.
///
/// Lifecycle is tied to the run, not the screen — [start] on starting or
/// resuming a run, [stop] on completing it or logging out. The backend
/// refuses anything sent outside an IN_PROGRESS run, which is the same
/// privacy line: off the clock, the driver is not tracked.
class DriverLocationReporter {
  DriverLocationReporter._();
  static final DriverLocationReporter instance = DriverLocationReporter._();

  /// The server does not rate-limit, so pacing is entirely on us.
  ///
  /// 15s is the agreed reporting cadence, and this is deliberately a second
  /// under it: set equal, jitter in OS delivery makes roughly every other fix
  /// land a few milliseconds early and get dropped, silently halving the real
  /// reporting rate.
  ///
  /// Everything downstream is sized against 15s — the 12s socket ack timeout
  /// fits inside one interval, and the parent retires an estimate after 90s,
  /// six missed pings. [LocationStream] asks the OS for the same cadence; this
  /// is the guarantee, because a time-based throttle cannot stall.
  static const Duration _minInterval = Duration(seconds: 14);

  /// The backend rejects the whole payload above 200 m rather than clamping
  /// it, so a poor fix is dropped here instead of being sent and refused.
  /// Early readings after a cold start are routinely worse than this.
  static const double _maxAccuracyMetres = 200;

  /// Consecutive drops, with nothing ever sent, before the accuracy gate is
  /// blamed on reduced location rather than a cold GPS.
  ///
  /// Early readings after a cold start are routinely worse than 200 m, so a
  /// handful of drops is normal; a run of them with not one fix through is
  /// the Precise-Location-off signature.
  static const int _droppedBeforeAccuracyBlamed = 5;

  /// How long without a fix before the stream is assumed dead and rebuilt.
  ///
  /// Aggressive OEM battery managers (Xiaomi/MIUI especially, which is what
  /// this was found on) will quietly stop delivering to a backgrounded
  /// listener without ever closing the stream or raising an error.
  ///
  /// Four missed intervals rather than three: at a 15s cadence a single poor
  /// fix is ordinary, and resubscribing on every one would churn the stream
  /// for no gain.
  static const Duration _staleAfter = Duration(seconds: 60);
  static const Duration _watchdogPeriod = Duration(seconds: 15);

  StreamSubscription<Position>? _sub;
  Timer? _watchdog;
  int? _routeId;
  DateTime? _lastSentAt;

  /// When a fix last arrived from the OS — distinct from [_lastSentAt], which
  /// only advances when a fix also passes the accuracy and rate filters.
  DateTime? _lastFixAt;

  /// Reports sent since the server last answered.
  ///
  /// A single unanswered report is normal — a tunnel, a lift, a cell
  /// handover. A run of them means the socket is up as far as the client can
  /// tell but nothing is arriving, which is the failure the driver cannot
  /// otherwise see.
  int _unacknowledged = 0;

  /// How many in a row before the connection is assumed dead and rebuilt.
  static const int _unacknowledgedLimit = 3;

  /// Whether the last report reached the server. Watched by the run screen so
  /// a driver is told when they have stopped being tracked.
  final ValueNotifier<bool> reporting = ValueNotifier(true);

  /// Live diagnostics. Always maintained; only rendered by DIAG builds.
  final ValueNotifier<ReporterDiagnostics> diagnostics =
      ValueNotifier(const ReporterDiagnostics());

  int _fixes = 0;
  int _dropped = 0;
  int _throttled = 0;
  int _sent = 0;
  int _acked = 0;
  double? _lastAccuracy;
  bool? _serviceEnabled;
  String? _permissionLabel;
  String? _accuracyLabel;

  void _publishDiag() {
    diagnostics.value = ReporterDiagnostics(
      subscribed: _sub != null,
      serviceEnabled: _serviceEnabled,
      permission: _permissionLabel,
      accuracy: _accuracyLabel,
      fixes: _fixes,
      dropped: _dropped,
      throttled: _throttled,
      sent: _sent,
      acked: _acked,
      lastFixAt: _lastFixAt,
      lastSentAt: _lastSentAt,
      lastAccuracy: _lastAccuracy,
      lastError: lastError.value,
    );
  }

  void _log(String message) {
    debugLog('location', message);
  }

  /// Last refusal from the server, so the UI can show that reporting is not
  /// working rather than leaving it silently broken.
  final ValueNotifier<String?> lastError = ValueNotifier(null);

  bool get isReporting => _sub != null;

  /// Whether iOS has the app on reduced (non-precise) location.
  ///
  /// Exposed so the run screen can tell the driver why nothing is being sent
  /// — the failure is otherwise completely invisible.
  final ValueNotifier<bool> reducedAccuracy = ValueNotifier(false);

  /// Begins reporting for [routeId]. Safe to call again for the same route.
  ///
  /// [notificationTitle]/[notificationText] are shown in the Android
  /// foreground-service notification, so they are passed in already localised.
  Future<void> start(
    int routeId, {
    required String notificationTitle,
    required String notificationText,
  }) async {
    if (_routeId == routeId && _sub != null) return;
    await stop();
    _routeId = routeId;
    lastError.value = null;

    try {
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _publishDiag();
      if (!_serviceEnabled!) {
        _log('location services disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      _permissionLabel = permission.name;
      _publishDiag();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _log('permission $permission');
        return;
      }

      await _ensurePreciseAccuracy();

      // Android's foreground-service notification is configured by whoever
      // starts the platform stream, so the copy has to be in place first.
      LocationStream.instance.setForegroundNotification(
        ForegroundNotificationText(
          title: notificationTitle,
          text: notificationText,
        ),
      );
      // A stream the map already started was configured without the
      // notification. Restarting is what promotes it to a foreground service;
      // without it Android kills location delivery as soon as the app is
      // backgrounded.
      if (LocationStream.instance.isRunning) {
        await LocationStream.instance.restart();
      }

      _subscribe();
      _watchdog = Timer.periodic(_watchdogPeriod, (_) => _checkAlive());
    } catch (e) {
      _log('start failed: $e');
      lastError.value = e.toString();
    }
  }

  void _subscribe() {
    _sub?.cancel();
    _lastFixAt = DateTime.now();
    _log('subscribing (route $_routeId)');
    _sub = LocationStream.instance
        .attach(this)
        .listen(
          _onPosition,
          onError: (Object e) {
            _log('stream error: $e');
            lastError.value = e.toString();
            _publishDiag();
          },
        );
    _publishDiag();
  }

  /// Asks iOS for temporary full accuracy when the driver has Precise
  /// Location switched off for this app.
  ///
  /// Without this the run fails in complete silence. iOS still reports the
  /// permission as `whileInUse` and still delivers fixes, but every one of
  /// them is hundreds of metres wide, so [_maxAccuracyMetres] drops all of
  /// them, nothing is ever sent, nothing ever times out, and the screen shows
  /// a perfectly healthy run while the school sees no bus at all.
  ///
  /// Non-iOS platforms always answer `precise`, so this is a no-op there.
  Future<void> _ensurePreciseAccuracy() async {
    try {
      var status = await Geolocator.getLocationAccuracy();
      if (status == LocationAccuracyStatus.reduced) {
        // Keyed to NSLocationTemporaryUsageDescriptionDictionary in
        // Info.plist. Grants full accuracy until the app is next restarted,
        // which comfortably covers one run.
        status = await Geolocator.requestTemporaryFullAccuracy(
          purposeKey: 'RunTracking',
        );
      }
      _accuracyLabel = status.name;
      _setReducedAccuracy(status == LocationAccuracyStatus.reduced);
    } catch (e) {
      // A missing purpose key throws PermissionDefinitionsNotFoundException.
      // Not fatal — carry on and let the accuracy gate report what it sees.
      _log('accuracy check failed: $e');
      _accuracyLabel = 'unknown';
    }
    _publishDiag();
  }

  void _setReducedAccuracy(bool reduced) {
    if (reducedAccuracy.value == reduced) return;
    reducedAccuracy.value = reduced;
    if (reduced) {
      _log('reduced accuracy — no fix will pass the gate');
      reporting.value = false;
    }
  }

  /// Rebuilds a stream that has gone quiet without erroring.
  ///
  /// Cheap to get wrong in the safe direction: a needless resubscribe costs
  /// one extra fix, whereas a missed one costs the rest of the run.
  void _checkAlive() {
    final last = _lastFixAt;
    if (_routeId == null || last == null) return;
    final silentFor = DateTime.now().difference(last);
    if (silentFor < _staleAfter) return;
    _log('no fix for ${silentFor.inSeconds}s — restarting the stream');
    // Restart the platform stream, not just this subscription: a stream that
    // has stopped delivering needs the OS location manager rebuilt, and
    // re-listening to the same Dart broadcast achieves nothing.
    _lastFixAt = DateTime.now();
    unawaited(LocationStream.instance.restart());
  }

  Future<void> stop() async {
    _watchdog?.cancel();
    _watchdog = null;
    await _sub?.cancel();
    _sub = null;
    // Releases this consumer's claim on the OS stream. The map may still hold
    // one, in which case the stream keeps running for the map alone.
    LocationStream.instance.setForegroundNotification(null);
    await LocationStream.instance.detach(this);
    // The map may still hold the stream open. Its Android service was started
    // with the run's ongoing notification, so rebuild it without one — an
    // "in progress" notification outliving the run tells the driver they are
    // still being tracked when they are not.
    if (LocationStream.instance.isRunning) {
      await LocationStream.instance.restart();
    }
    _routeId = null;
    _lastSentAt = null;
    _lastFixAt = null;
    _unacknowledged = 0;
    _fixes = 0;
    _dropped = 0;
    _throttled = 0;
    _sent = 0;
    _acked = 0;
    _lastAccuracy = null;
    _accuracyLabel = null;
    reducedAccuracy.value = false;
    reporting.value = true;
    lastError.value = null;
    _publishDiag();
  }

  void _onPosition(Position position) {
    final routeId = _routeId;
    if (routeId == null) return;

    final now = DateTime.now();
    // Set before the filters below: a fix that arrives and is discarded still
    // proves the stream is alive, so it must not trip the watchdog.
    _lastFixAt = now;
    _fixes++;
    _lastAccuracy = position.accuracy;

    // A fix the server would reject outright is not worth a round trip.
    if (position.accuracy > _maxAccuracyMetres) {
      _log('dropped: accuracy ${position.accuracy.toStringAsFixed(0)}m');
      _dropped++;
      // Fixes this wide are what iOS delivers with Precise Location off. Say
      // so rather than silently discarding every one of them for the whole
      // run: the driver can fix this in Settings, but only if told.
      if (_dropped >= _droppedBeforeAccuracyBlamed && _sent == 0) {
        _setReducedAccuracy(true);
      }
      _publishDiag();
      return;
    }
    // Precision came back — the driver turned it on, or the temporary grant
    // finally landed.
    _setReducedAccuracy(false);

    final last = _lastSentAt;
    if (last != null && now.difference(last) < _minInterval) {
      _throttled++;
      _publishDiag();
      return;
    }
    _lastSentAt = now;
    _sent++;
    _publishDiag();

    _log(
      'emit ${position.latitude.toStringAsFixed(5)},'
      '${position.longitude.toStringAsFixed(5)} '
      '±${position.accuracy.toStringAsFixed(0)}m',
    );

    SocketService.instance.emitDriverLocation({
      'routeid': routeId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      // Geolocator reports -1 when it cannot determine these; the backend
      // range-checks them and stores out-of-range values as null, so -1
      // passes through as "unknown" rather than a bogus reading.
      'speed': position.speed,
      'heading': position.heading,
      // The fix's own timestamp, not send time: the server orders by this
      // and drops anything older than what it already holds.
      'recorded_at': position.timestamp.toUtc().toIso8601String(),
    }, onStored: () {
      _log('stored');
      _onAcknowledged();
    }, onStale: () {
      // The server answered; the guard simply had a fresher fix already.
      _log('dropped as stale');
      _onAcknowledged();
    }, onRefused: (message) {
      // A refusal is still an answer: the link works, the request did not.
      _log('refused by server: $message');
      _unacknowledged = 0;
      reporting.value = true;
      lastError.value = message;
      _publishDiag();
    }, onTimeout: _onUnacknowledged);
  }

  void _onAcknowledged() {
    _unacknowledged = 0;
    _acked++;
    reporting.value = true;
    lastError.value = null;
    _publishDiag();
  }

  /// No answer came back within the ack window.
  void _onUnacknowledged() {
    _unacknowledged++;
    _log('no acknowledgement ($_unacknowledged in a row)');
    if (_unacknowledged < _unacknowledgedLimit) return;

    // Rebuild rather than wait: socket.io only reconnects a transport it
    // knows has dropped, and this failure looks connected from the client.
    reporting.value = false;
    lastError.value = 'not_reporting';
    _log('rebuilding socket after $_unacknowledged unanswered reports');
    SocketService.instance.rebuild();
    _unacknowledged = 0;
    _publishDiag();
  }
}
