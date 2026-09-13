import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:mockup/Widgets/Parent%20Widgets/pr_boarding_widget.dart';
import 'package:mockup/l10n/app_localizations.dart';
import 'package:mockup/services/api_client.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:mockup/services/socket_service.dart';

/// What the parent is told when the live feed stops.
///
/// After its first load this screen is driven entirely by socket events, so a
/// dropped feed leaves it showing a status that may have moved on — a parent
/// reading "on the bus" long after the child reached school. The banner is the
/// only thing standing between that and silent misinformation, and the
/// re-sync is what makes the screen correct again once the feed returns.
///
/// No access token is set on purpose: SocketService.connect() returns early
/// without one, so no real socket is opened and `connected` stays a plain
/// value this test can drive.
void main() {
  var attendanceCalls = 0;

  setUp(() {
    attendanceCalls = 0;
    AuthSession.instance.accessToken = null;
    SocketService.instance.connected.value = false;

    ApiClient.resetForTesting(
      withClient: MockClient((request) async {
        final path = request.url.path;
        String body;
        if (path.endsWith('/students')) {
          body = jsonEncode({
            'students': [
              {'id': 1, 'first_name': 'ibrahim', 'status': '', 'routeid': 7},
            ],
          });
        } else if (path.contains('/attendance/')) {
          attendanceCalls++;
          body = jsonEncode({
            'attendance': {
              'attendanceid': 11,
              'studentid': 1,
              'current_status': 'WAITING',
              'current_phase': 'morning',
            },
          });
        } else {
          // absence listing
          body = jsonEncode({'from': '2026-09-13', 'absences': const []});
        }
        return http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  tearDown(() {
    ApiClient.resetForTesting();
    SocketService.instance.connected.value = false;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: PrBoardingWidget()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a down feed says so rather than looking live', (tester) async {
    await pump(tester);
    expect(
      find.text('Live updates paused — this may be out of date'),
      findsOneWidget,
    );
  });

  testWidgets('the warning clears when the feed comes back', (tester) async {
    await pump(tester);

    SocketService.instance.connected.value = true;
    await tester.pumpAndSettle();

    expect(
      find.text('Live updates paused — this may be out of date'),
      findsNothing,
    );
  });

  testWidgets('coming back re-reads what the feed missed', (tester) async {
    await pump(tester);
    final afterLoad = attendanceCalls;
    expect(afterLoad, greaterThan(0), reason: 'first load should fetch status');

    // The regression this guards: reconnecting used to repaint nothing and
    // fetch nothing, so anything that happened while the socket was down
    // stayed invisible until the parent thought to pull-to-refresh.
    SocketService.instance.connected.value = true;
    await tester.pumpAndSettle();

    expect(attendanceCalls, greaterThan(afterLoad));
  });

  testWidgets('returning to the app re-reads the status', (tester) async {
    await pump(tester);
    final afterLoad = attendanceCalls;

    // The other way a gap opens: the phone was in a pocket. The socket may
    // never report a change, so resume is its own trigger.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(attendanceCalls, greaterThan(afterLoad));
  });

  testWidgets('losing the feed does not refetch, only warns', (tester) async {
    await pump(tester);
    SocketService.instance.connected.value = true;
    await tester.pumpAndSettle();
    final afterReconnect = attendanceCalls;

    SocketService.instance.connected.value = false;
    await tester.pumpAndSettle();

    expect(attendanceCalls, afterReconnect);
    expect(
      find.text('Live updates paused — this may be out of date'),
      findsOneWidget,
    );
  });
}
