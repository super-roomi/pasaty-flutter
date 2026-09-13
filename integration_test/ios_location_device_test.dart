@Tags(['device'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockup/services/driver_location_reporter.dart';
import 'package:mockup/services/location_stream.dart';

/// The location layer against real CoreLocation, on a real handset.
///
/// The channel-level suite (`test/ios_location_stream_test.dart`) proves what
/// arguments we send the platform. It cannot prove the OS accepts them, that a
/// receiver actually starts, or that a restart recovers — for that you need a
/// device with a real GPS.
///
/// Deliberately does not touch the backend. [DriverLocationReporter] hands its
/// payloads to [SocketService], which returns immediately when there is no
/// session, so nothing leaves the handset: the reporter simply counts the
/// report as unacknowledged, which is the correct behaviour and is not what is
/// under test here.
///
/// Run it:
///   flutter test integration_test/ios_location_device_test.dart \
///     -d `<device-id>` --dart-define-from-file=dart_defines.json
///
/// Location permission must already be granted — an integration test cannot
/// tap a system alert. If the run reports `denied`, grant it once by hand and
/// run again.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Waits for the first fix, or gives up. Returns null on timeout rather than
  /// throwing, so a run indoors reports "no fix" instead of a stack trace.
  Future<Position?> firstFix(
    Stream<Position> stream, {
    Duration within = const Duration(seconds: 45),
  }) async {
    try {
      return await stream.first.timeout(within);
    } on TimeoutException {
      return null;
    }
  }

  testWidgets('the handset reports what it is willing to give us', (
    tester,
  ) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final accuracy = await Geolocator.getLocationAccuracy();

    // ignore: avoid_print
    print(
      'DEVICE-STATE services=$enabled permission=${permission.name} '
      'accuracy=${accuracy.name}',
    );

    expect(
      enabled,
      isTrue,
      reason: 'Location Services are off for the whole device',
    );
    expect(
      permission,
      anyOf(LocationPermission.whileInUse, LocationPermission.always),
      reason: 'grant location permission by hand, then re-run',
    );
  });

  testWidgets('a real receiver starts and delivers a fix', (tester) async {
    final stream = LocationStream.instance.attach('device-test');
    addTearDown(() => LocationStream.instance.detach('device-test'));

    expect(LocationStream.instance.isRunning, isTrue);

    final fix = await tester.runAsync(() => firstFix(stream));

    // ignore: avoid_print
    print(
      fix == null
          ? 'FIRST-FIX none within 45s'
          : 'FIRST-FIX ${fix.latitude.toStringAsFixed(5)},'
                '${fix.longitude.toStringAsFixed(5)} '
                '±${fix.accuracy.toStringAsFixed(0)}m',
    );

    expect(fix, isNotNull, reason: 'CoreLocation delivered nothing in 45s');

    // The gate the reporter applies. Indoors this can legitimately fail on the
    // very first fix, which is itself worth seeing in the output.
    // ignore: avoid_print
    print(
      fix!.accuracy <= 200
          ? 'GATE pass — this fix would be reported'
          : 'GATE fail — ±${fix.accuracy.toStringAsFixed(0)}m exceeds 200m',
    );
  });

  testWidgets('a restart rebuilds the receiver and fixes resume', (
    tester,
  ) async {
    final stream = LocationStream.instance.attach('device-test');
    addTearDown(() => LocationStream.instance.detach('device-test'));

    final before = await tester.runAsync(() => firstFix(stream));
    expect(before, isNotNull, reason: 'no fix before the restart');

    // The watchdog path. On the old code this issued no platform call at all
    // when a second consumer was attached, so a stalled receiver could never
    // be recovered.
    final map = LocationStream.instance.attach('fake-map');
    addTearDown(() => LocationStream.instance.detach('fake-map'));
    map.listen((_) {});

    await tester.runAsync(() => LocationStream.instance.restart());
    expect(LocationStream.instance.isRunning, isTrue);

    final after = await tester.runAsync(() => firstFix(stream));
    // ignore: avoid_print
    print(
      after == null
          ? 'RESTART no fix within 45s — receiver did not come back'
          : 'RESTART recovered, ±${after.accuracy.toStringAsFixed(0)}m',
    );
    expect(after, isNotNull, reason: 'the receiver did not come back');
  });

  testWidgets('the receiver stops when the last consumer detaches', (
    tester,
  ) async {
    LocationStream.instance.attach('device-test').listen((_) {});
    expect(LocationStream.instance.isRunning, isTrue);

    await tester.runAsync(
      () => LocationStream.instance.detach('device-test'),
    );

    expect(LocationStream.instance.isRunning, isFalse);
    // ignore: avoid_print
    print('LIFECYCLE receiver released');
  });

  testWidgets('a run drives the reporter end to end, minus the backend', (
    tester,
  ) async {
    await DriverLocationReporter.instance.start(
      1,
      notificationTitle: 'Run in progress',
      notificationText: 'Sharing the bus location until the run ends',
    );
    addTearDown(DriverLocationReporter.instance.stop);

    expect(
      DriverLocationReporter.instance.isReporting,
      isTrue,
      reason: 'the reporter never subscribed',
    );

    // Long enough for a cold GPS to settle and for the 14s throttle to let a
    // second fix through.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 40)),
    );

    final diag = DriverLocationReporter.instance.diagnostics.value;
    // ignore: avoid_print
    print(
      'REPORTER fixes=${diag.fixes} dropped=${diag.dropped} '
      'throttled=${diag.throttled} sent=${diag.sent} '
      'accuracy=${diag.accuracy} permission=${diag.permission} '
      'last=${diag.lastAccuracy?.toStringAsFixed(0)}m '
      'reduced=${DriverLocationReporter.instance.reducedAccuracy.value}',
    );

    expect(diag.fixes, greaterThan(0), reason: 'no fix reached the reporter');
    expect(
      diag.sent,
      greaterThan(0),
      reason:
          'nothing passed the accuracy gate in 40s — this is the silent '
          'failure mode; check accuracy= in the line above',
    );
    expect(DriverLocationReporter.instance.reducedAccuracy.value, isFalse);
  });
}
