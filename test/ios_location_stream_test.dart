@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:mockup/services/driver_location_reporter.dart';
import 'package:mockup/services/location_stream.dart';

/// What the iOS side of geolocator actually receives.
///
/// Everything about background location on iOS is decided by the arguments
/// that reach `PositionStreamHandler.onListenWithArguments:` — that is the one
/// and only place `allowsBackgroundLocationUpdates`,
/// `pausesLocationUpdatesAutomatically` and `showsBackgroundLocationIndicator`
/// are set on the CLLocationManager. Asserting on the Dart settings objects we
/// build proves nothing, because `GeolocatorApple.getPositionStream` caches
/// the first stream it made and throws every later `locationSettings`
/// argument away. So these tests intercept the platform channel itself and
/// assert on what crossed it.
const _methodChannel = 'flutter.baseflow.com/geolocator_apple';
const _updatesChannel = 'flutter.baseflow.com/geolocator_updates_apple';

/// One `listen`/`cancel` seen on the position-stream channel.
class _ChannelCall {
  final String method;
  final Map<Object?, Object?>? arguments;
  _ChannelCall(this.method, this.arguments);

  @override
  String toString() => '$method(${arguments ?? {}})';
}

/// Stands in for the driver's map card: a second consumer of the shared
/// stream, attached and detached the way [DvRouteMap] does it.
class _FakeMapConsumer {
  Object? _sub;

  void open() {
    _sub = LocationStream.instance.attach(this).listen((_) {});
  }

  Future<void> close() async {
    await (_sub as dynamic)?.cancel();
    _sub = null;
    await LocationStream.instance.detach(this);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<_ChannelCall> calls;
  late TestDefaultBinaryMessenger messenger;

  /// What `getLocationAccuracy` answers: index into LocationAccuracyStatus,
  /// so 0 = reduced, 1 = precise.
  late int accuracyStatus;

  /// Whether iOS grants full accuracy when asked for it temporarily.
  late bool grantsTemporaryAccuracy;

  const codec = StandardMethodCodec();

  /// Hands a fix to whatever is listening, exactly as the native side would.
  Future<void> emitFix({double accuracy = 8}) async {
    await messenger.handlePlatformMessage(
      _updatesChannel,
      codec.encodeSuccessEnvelope(<String, Object?>{
        'latitude': 35.5,
        'longitude': 45.4,
        'accuracy': accuracy,
        'altitude': 0.0,
        'altitude_accuracy': 0.0,
        'heading': 0.0,
        'heading_accuracy': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
      }),
      (_) {},
    );
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // Register the real iOS implementation so the code under test runs against
    // the same GeolocatorApple that ships, stream caching included.
    GeolocatorApple.registerWith();

    calls = [];
    accuracyStatus = 1; // precise
    grantsTemporaryAccuracy = true;
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(const MethodChannel(_methodChannel), (
      call,
    ) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
        case 'requestPermission':
          return 2; // LocationPermission.whileInUse
        case 'getLocationAccuracy':
          return accuracyStatus;
        case 'requestTemporaryFullAccuracy':
          return grantsTemporaryAccuracy ? 1 : 0;
        default:
          return null;
      }
    });

    messenger.setMockMethodCallHandler(const MethodChannel(_updatesChannel), (
      call,
    ) async {
      calls.add(
        _ChannelCall(call.method, call.arguments as Map<Object?, Object?>?),
      );
      return null;
    });
  });

  tearDown(() async {
    await DriverLocationReporter.instance.stop();
    messenger.setMockMethodCallHandler(
      const MethodChannel(_methodChannel),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel(_updatesChannel),
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> startRun([int routeId = 1]) => DriverLocationReporter.instance
      .start(routeId, notificationTitle: 'Run', notificationText: 'Sharing');

  Map<Object?, Object?> lastListenArgs() {
    final listens = calls.where((c) => c.method == 'listen').toList();
    expect(listens, isNotEmpty, reason: 'nothing ever started on the channel');
    return listens.last.arguments!;
  }

  group('background settings reach CoreLocation', () {
    test('a run started on its own configures the location manager', () async {
      await startRun();

      final args = lastListenArgs();
      expect(args['allowBackgroundLocationUpdates'], isTrue);
      expect(args['showBackgroundLocationIndicator'], isTrue);
      expect(args['pauseLocationUpdatesAutomatically'], isFalse);
      expect(args['distanceFilter'], 0);
    });

    test(
      'a run started while the map is already open still configures it',
      () async {
        // The regression. The map used to open its own stream; the plugin then
        // handed the reporter that same stream and discarded the reporter's
        // settings, so the run tracked with the map's configuration and the
        // driver got no blue status-bar indicator.
        final map = _FakeMapConsumer()..open();
        addTearDown(map.close);
        await pumpEventQueue();

        await startRun();
        await pumpEventQueue();

        final args = lastListenArgs();
        expect(args['allowBackgroundLocationUpdates'], isTrue);
        expect(args['showBackgroundLocationIndicator'], isTrue);
        expect(args['pauseLocationUpdatesAutomatically'], isFalse);
      },
    );

    test('both consumers share one platform subscription', () async {
      final map = _FakeMapConsumer()..open();
      addTearDown(map.close);
      await startRun();
      await pumpEventQueue();

      var received = 0;
      final probe = LocationStream.instance.attach('probe').listen((_) {
        received++;
      });
      addTearDown(() async {
        await probe.cancel();
        await LocationStream.instance.detach('probe');
      });

      await emitFix();
      await pumpEventQueue();

      expect(received, 1);
      expect(DriverLocationReporter.instance.diagnostics.value.fixes, 1);
    });
  });

  group('watchdog recovery', () {
    test('a restart cancels before it listens again', () async {
      await startRun();
      await pumpEventQueue();
      calls.clear();

      await LocationStream.instance.restart();
      await pumpEventQueue();

      // Order matters: iOS answers a `listen` that arrives while a sink is
      // still installed with LOCATION_SUBSCRIPTION_ACTIVE and starts no
      // location manager at all.
      expect(calls.map((c) => c.method).toList(), ['cancel', 'listen']);
    });

    test('a restart still reaches the platform while the map listens', () async {
      await startRun();
      final map = _FakeMapConsumer()..open();
      addTearDown(map.close);
      await pumpEventQueue();
      calls.clear();

      await LocationStream.instance.restart();
      await pumpEventQueue();

      // Previously this issued no platform call whatsoever, so a stalled
      // location manager could never be recovered while the map was open —
      // which is exactly when a driver goes looking at it.
      expect(calls.map((c) => c.method).toList(), ['cancel', 'listen']);
      expect(lastListenArgs()['showBackgroundLocationIndicator'], isTrue);
    });
  });

  group('consumer lifecycle', () {
    test('the receiver stops when the last consumer detaches', () async {
      final map = _FakeMapConsumer()..open();
      await pumpEventQueue();
      expect(LocationStream.instance.isRunning, isTrue);

      await map.close();
      await pumpEventQueue();

      expect(LocationStream.instance.isRunning, isFalse);
      expect(calls.map((c) => c.method).toList(), ['listen', 'cancel']);
    });

    test('closing the map mid-run leaves the run reporting', () async {
      await startRun();
      final map = _FakeMapConsumer()..open();
      await pumpEventQueue();

      await map.close();
      await pumpEventQueue();

      expect(LocationStream.instance.isRunning, isTrue);
      await emitFix();
      await pumpEventQueue();
      expect(DriverLocationReporter.instance.diagnostics.value.fixes, 1);
    });
  });

  group('reduced accuracy', () {
    test('a run asks for temporary full accuracy when precise is off', () async {
      accuracyStatus = 0; // reduced
      await startRun();

      expect(DriverLocationReporter.instance.reducedAccuracy.value, isFalse);
      expect(
        DriverLocationReporter.instance.diagnostics.value.accuracy,
        'precise',
      );
    });

    test('a driver who refuses full accuracy is told, not ignored', () async {
      accuracyStatus = 0;
      grantsTemporaryAccuracy = false;
      await startRun();

      // The failure this makes visible: iOS keeps reporting "when in use" and
      // keeps delivering fixes, but every one is far too wide for the backend
      // to accept, so a run would otherwise report nothing at all while the
      // screen looked perfectly healthy.
      expect(DriverLocationReporter.instance.reducedAccuracy.value, isTrue);
      expect(DriverLocationReporter.instance.reporting.value, isFalse);
    });

    test('wide fixes with nothing sent raise the flag mid-run', () async {
      await startRun();
      await pumpEventQueue();
      expect(DriverLocationReporter.instance.reducedAccuracy.value, isFalse);

      for (var i = 0; i < 5; i++) {
        await emitFix(accuracy: 1500);
      }
      await pumpEventQueue();

      final diag = DriverLocationReporter.instance.diagnostics.value;
      expect(diag.dropped, 5);
      expect(diag.sent, 0);
      expect(DriverLocationReporter.instance.reducedAccuracy.value, isTrue);
    });

    test('the flag clears as soon as a usable fix arrives', () async {
      await startRun();
      for (var i = 0; i < 5; i++) {
        await emitFix(accuracy: 1500);
      }
      await pumpEventQueue();
      expect(DriverLocationReporter.instance.reducedAccuracy.value, isTrue);

      await emitFix(accuracy: 10);
      await pumpEventQueue();

      expect(DriverLocationReporter.instance.reducedAccuracy.value, isFalse);
    });
  });
}
