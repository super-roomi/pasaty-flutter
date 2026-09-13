@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/Util/child_location_ui.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_trip_progress_widget.dart';
import 'package:mockup/l10n/app_localizations.dart';
import 'package:mockup/services/api_config.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:mockup/services/socket_service.dart';

/// The parent's arrival line, driven over a real socket.
///
/// Everything here is the shipping code path: the real [SocketService]
/// opening a real websocket, the real `eta:updated` decoding, and the real
/// widget. Only two things are stood in for — authentication, and the
/// driver's phone. The payload itself is generated server-side by the
/// backend's own `buildEstimate()` against the real route geometry and
/// waypoint stations.
///
/// Run against the helper server:
///   node eta_test_server.js 4599
///   flutter test --dart-define=API_BASE_URL=http://127.0.0.1:4599 \
///     --tags integration test/eta_socket_integration_test.dart
void main() {
  testWidgets('a live eta:updated becomes a readable arrival time', (
    tester,
  ) async {
    expect(
      ApiConfig.baseUrl,
      contains('127.0.0.1'),
      reason: 'run with --dart-define=API_BASE_URL=http://127.0.0.1:<port>',
    );

    // The socket refuses to open without a session; the helper server does not
    // validate it.
    AuthSession.instance.accessToken = 'integration-test-token';

    final service = SocketService.instance;
    final received = <RouteEta>[];
    final sub = service.etaEvents.listen(received.add);

    // testWidgets drives a fake clock, so real socket I/O never progresses
    // inside it. runAsync hands control back to the actual event loop for the
    // duration of the connection.
    await tester.runAsync(() async {
      service.joinRoute(1);
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      while (received.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      // Close the socket while the real event loop is still running.
      // socket.io keeps reconnect timers alive, and tearing it down after
      // runAsync leaves them pending, which hangs the test process.
      await sub.cancel();
      service.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });

    expect(
      received,
      isNotEmpty,
      reason: 'no eta:updated arrived over the socket',
    );

    final eta = received.first;
    expect(eta.routeId, 1);
    expect(eta.phase, 'afternoon');

    // With the bus at the school, every student on the route is still ahead
    // of it — nobody has been dropped off yet.
    expect(
      eta.byStudent.keys,
      containsAll(<int>[1, 2, 17, 23, 24]),
      reason: 'expected all five stops ahead of a bus at the school',
    );
    expect(eta.lowConfidence, isFalse, reason: 'bus is exactly on the line');

    // meran is the first stop after the school; zain is the last. One should
    // read as arriving, the other as a real number of minutes.
    final meran = eta.byStudent[24]!;
    final zain = eta.byStudent[17]!;

    final zainWait = zain.eta.difference(DateTime.now());
    expect(
      zainWait.inSeconds,
      greaterThan(60),
      reason: 'expected minutes away, got ${zainWait.inSeconds}s',
    );
    expect(
      zainWait.inMinutes,
      lessThan(120),
      reason: 'implausible estimate: ${zainWait.inMinutes} min',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrTripProgressWidget(
              afternoon: eta.phase == 'afternoon',
              // meran is the first stop after the school — the next arrival.
              eta: TripEta(
                arrival: meran.eta,
                metersAway: meran.metersAway,
                approximate: eta.lowConfidence,
              ),
              children: const [
                TripProgressChild(
                  name: 'meran',
                  location: ChildLocation.inSchool,
                ),
                TripProgressChild(
                  name: 'zain',
                  location: ChildLocation.inSchool,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The bus is at the school, so the nearest stop is seconds away and the
    // card correctly says so rather than inventing a range.
    expect(find.text('Arriving home now'), findsOneWidget);

    // Exactly one estimate for the pair, not one per child.
    expect(find.byIcon(Icons.schedule), findsOneWidget);

    debugPrint(
      'rendered one estimate covering meran (${meran.metersAway}m) '
      'and zain (${zain.metersAway}m, ${zainWait.inMinutes}min)',
    );

  }, timeout: const Timeout(Duration(seconds: 90)));
}
