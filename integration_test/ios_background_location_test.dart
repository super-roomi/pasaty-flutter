@Tags(['device'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockup/services/driver_location_reporter.dart';

/// Does the run keep reporting once the screen locks?
///
/// This is the whole feature, and it is the one thing no automated harness can
/// assert on its own — the app has to actually leave the foreground, which
/// means a person has to press the side button. So the test does not try to
/// drive the transition; it watches for one, and judges the run on whether
/// fixes kept arriving across it.
///
/// **Lock the phone when the console says to, and leave it locked until it
/// says to wake it.**
///
/// What a pass means: CoreLocation kept delivering while
/// `AppLifecycleState` was not `resumed`. That is `UIBackgroundModes:
/// location` plus `allowsBackgroundLocationUpdates` working end to end, on
/// this handset, on this iOS version.
///
///   flutter test integration_test/ios_background_location_test.dart \
///     -d `<device-id>` --dart-define-from-file=dart_defines.json
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// One second of the run: how many fixes had arrived and what the app's
  /// lifecycle state was at the time.
  final samples = <({int atSecond, int fixes, int sent, String lifecycle})>[];

  testWidgets('fixes keep arriving while the screen is locked', (tester) async {
    final observer = _LifecycleProbe();
    WidgetsBinding.instance.addObserver(observer);
    addTearDown(() => WidgetsBinding.instance.removeObserver(observer));

    await DriverLocationReporter.instance.start(
      1,
      notificationTitle: 'Run in progress',
      notificationText: 'Sharing the bus location until the run ends',
    );
    addTearDown(DriverLocationReporter.instance.stop);

    expect(DriverLocationReporter.instance.isReporting, isTrue);

    const total = 90;
    const lockAt = 10;
    const wakeAt = 75;

    await tester.runAsync(() async {
      for (var second = 0; second < total; second++) {
        if (second == 0) {
          _say('running — settle for ${lockAt}s, then LOCK THE PHONE');
        }
        if (second == lockAt) {
          _say('>>> LOCK THE PHONE NOW (side button) — leave it locked <<<');
        }
        if (second == wakeAt) {
          _say('>>> WAKE AND UNLOCK THE PHONE NOW <<<');
        }

        await Future<void>.delayed(const Duration(seconds: 1));

        final diag = DriverLocationReporter.instance.diagnostics.value;
        samples.add((
          atSecond: second + 1,
          fixes: diag.fixes,
          sent: diag.sent,
          lifecycle: observer.state,
        ));

        // A heartbeat every 5s, so a stall is visible as it happens rather
        // than only in the summary.
        if ((second + 1) % 5 == 0) {
          _say(
            't=${second + 1}s fixes=${diag.fixes} sent=${diag.sent} '
            'state=${observer.state}',
          );
        }
      }
    });

    _say('--- transitions ---');
    for (final t in observer.transitions) {
      _say('  ${t.$1}s -> ${t.$2}');
    }

    final away = samples.where((s) => s.lifecycle != 'resumed').toList();

    _say('--- verdict ---');
    if (away.isEmpty) {
      _say('the app never left the foreground — nothing was tested');
    } else {
      final first = away.first;
      final last = away.last;
      _say(
        'backgrounded ${first.atSecond}s..${last.atSecond}s: '
        'fixes ${first.fixes}->${last.fixes} (+${last.fixes - first.fixes}), '
        'sent ${first.sent}->${last.sent} (+${last.sent - first.sent})',
      );
    }

    expect(
      away,
      isNotEmpty,
      reason:
          'the phone was never locked, so background delivery was not '
          'exercised — re-run and lock when prompted',
    );

    final gained = away.last.fixes - away.first.fixes;
    final reported = away.last.sent - away.first.sent;
    final seconds = away.last.atSecond - away.first.atSecond;

    expect(
      gained,
      greaterThan(0),
      reason:
          'CoreLocation stopped delivering the moment the app left the '
          'foreground — background location is not working',
    );

    // The real contract is not "some fixes" but "a report roughly every 15s".
    // Allow one interval of slack for the transition itself.
    final expectedReports = (seconds / 15).floor() - 1;
    expect(
      reported,
      greaterThanOrEqualTo(expectedReports),
      reason:
          'only $reported reports in ${seconds}s backgrounded; expected at '
          'least $expectedReports at a 15s cadence',
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}

/// Records lifecycle changes with the second they happened.
class _LifecycleProbe with WidgetsBindingObserver {
  final DateTime _start = DateTime.now();
  String state = 'resumed';
  final List<(int, String)> transitions = [];

  @override
  void didChangeAppLifecycleState(AppLifecycleState next) {
    state = next.name;
    transitions.add((DateTime.now().difference(_start).inSeconds, next.name));
  }
}

void _say(String message) {
  // ignore: avoid_print
  print('BG $message');
}
