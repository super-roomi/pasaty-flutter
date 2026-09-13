import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mockup/Util/debug_log.dart';
import 'package:geolocator/geolocator.dart';

/// The app's one and only subscription to the OS position stream.
///
/// Nothing else may call [Geolocator.getPositionStream] directly. That is not
/// a style rule — it is forced by how the plugin behaves.
///
/// `GeolocatorApple.getPositionStream` (and its Android twin) caches the
/// stream it built the first time and returns that same object for every
/// later call, **silently discarding the `locationSettings` argument**. Two
/// callers therefore do not get two differently-configured streams; the
/// second one gets the first one's CLLocationManager. When the driver opened
/// the route map before starting a run, the run reporter's
/// `showBackgroundLocationIndicator` and accuracy settings never reached
/// CoreLocation at all — the map's did, and reporting ran for the whole run
/// against a manager nobody meant to configure.
///
/// The same cache breaks recovery. Cancelling one of two subscriptions is not
/// the last cancel, so the plugin issues no `cancel` on the platform channel
/// and keeps its cached stream; a "resubscribe" then re-listens to a Dart
/// broadcast stream without ever restarting the native location manager. The
/// reporter's stale-stream watchdog was a no-op whenever the map was open —
/// exactly the situation a driver is in when they notice a problem and go
/// looking at the map.
///
/// So: one subscription, owned here, with one set of settings. Consumers
/// [attach] and [detach]; the platform stream runs while at least one is
/// attached and is genuinely torn down when the last one leaves.
class LocationStream {
  LocationStream._();
  static final LocationStream instance = LocationStream._();

  /// Deliberately 0 on every platform.
  ///
  /// Android turns a non-zero filter into `setMinUpdateDistanceMeters` and
  /// iOS into `CLLocationManager.distanceFilter`; both then suppress *every*
  /// fix until the phone has physically moved that far. A bus at a stop, in
  /// traffic, or a driver testing at a desk reports one position for the whole
  /// run. Pacing is the reporter's job, and a time-based throttle cannot
  /// stall.
  static const int _distanceFilterMetres = 0;

  /// Requested from the OS. The reporter's own throttle is the real cadence
  /// guarantee; this just stops the platform waking us more often than useful.
  static const Duration _updateInterval = Duration(seconds: 15);

  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();

  /// Who currently wants fixes. Identity-based, so a consumer attaching twice
  /// is not counted twice and cannot detach the other one.
  final Set<Object> _consumers = {};

  StreamSubscription<Position>? _platformSub;

  /// Whether the platform stream is currently running.
  bool get isRunning => _platformSub != null;

  @visibleForTesting
  int get consumerCount => _consumers.length;

  void _log(String message) {
    debugLog('location-stream', message);
  }

  /// Fixes from the OS, shared by every consumer.
  ///
  /// [consumer] is any object identifying the caller — pass `this`. Cancelling
  /// the returned subscription is not enough on its own; call [detach] too, or
  /// the platform stream keeps running for a consumer that has gone away.
  Stream<Position> attach(Object consumer) {
    final added = _consumers.add(consumer);
    if (added) _log('attach ${consumer.runtimeType} (${_consumers.length})');
    _start();
    return _controller.stream;
  }

  /// Releases [consumer]'s claim, stopping the OS stream if it was the last.
  Future<void> detach(Object consumer) async {
    if (!_consumers.remove(consumer)) return;
    _log('detach ${consumer.runtimeType} (${_consumers.length} left)');
    if (_consumers.isEmpty) await _stop();
  }

  /// Tears the platform stream down and builds a fresh one.
  ///
  /// For a stream that has gone quiet without erroring — aggressive OEM
  /// battery managers do this, and so does iOS after some authorisation
  /// changes. Because this owns the only subscription, the cancel really is
  /// the last one, so the plugin drops its cache and the native location
  /// manager is genuinely restarted. Awaited end to end: the platform `listen`
  /// must not be issued before the `cancel` it is meant to follow, or iOS
  /// answers the second one with `LOCATION_SUBSCRIPTION_ACTIVE` and no
  /// location manager is left running at all.
  Future<void> restart() async {
    if (_consumers.isEmpty) return;
    _log('restarting platform stream');
    await _stop();
    _start();
  }

  void _start() {
    if (_platformSub != null || _consumers.isEmpty) return;
    _log('starting platform stream');
    _platformSub = Geolocator.getPositionStream(locationSettings: _settings())
        .listen(
          _controller.add,
          onError: (Object e, StackTrace s) {
            _log('platform error: $e');
            _controller.addError(e, s);
          },
        );
  }

  Future<void> _stop() async {
    final sub = _platformSub;
    if (sub == null) return;
    _platformSub = null;
    // Awaited, not fire-and-forget: this is what makes the plugin release its
    // cached stream and send `cancel` down the channel.
    await sub.cancel();
    _log('platform stream stopped');
  }

  /// The one settings object, sized for a moving bus.
  ///
  /// Android: a foreground service with an ongoing notification. That counts
  /// as "in use", so ACCESS_BACKGROUND_LOCATION is not needed — less invasive
  /// and far easier to get through Play review. Title and text come from
  /// [notification], already localised.
  ///
  /// iOS: background location updates under the `location` UIBackgroundMode.
  /// "When In Use" authorisation is enough for this and shows the blue status
  /// bar, so the driver can always see they are being located; asking for
  /// "Always" would buy nothing here and invites extra App Review scrutiny.
  LocationSettings _settings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final notification = _notification;
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilterMetres,
          intervalDuration: _updateInterval,
          foregroundNotificationConfig: notification == null
              ? null
              : ForegroundNotificationConfig(
                  notificationTitle: notification.title,
                  notificationText: notification.text,
                  enableWakeLock: true,
                  setOngoing: true,
                ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilterMetres,
          allowBackgroundLocationUpdates: true,
          // Always on, not only while a run is active. It is the driver's one
          // visible signal that the app is locating them, and the Info.plist
          // copy promises it.
          showBackgroundLocationIndicator: true,
          // iOS pauses updates when it thinks you have stopped moving; on a
          // bus that idles in traffic or at a stop, that silently ends the
          // reporting for the rest of the run.
          pauseLocationUpdatesAutomatically: false,
          activityType: ActivityType.automotiveNavigation,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: _distanceFilterMetres,
        );
    }
  }

  ForegroundNotificationText? _notification;

  /// Supplies the Android foreground-service notification copy.
  ///
  /// Set before the run's [attach] so the service starts with it, and cleared
  /// when the run ends. Only Android reads this; on iOS the OS owns the
  /// indicator and there is nothing to configure.
  ///
  /// Changing it after the stream is running does not restyle a live
  /// notification — call [restart] if that is ever needed.
  void setForegroundNotification(ForegroundNotificationText? notification) {
    _notification = notification;
  }
}

/// Localised copy for the Android foreground-service notification.
class ForegroundNotificationText {
  final String title;
  final String text;
  const ForegroundNotificationText({required this.title, required this.text});
}
