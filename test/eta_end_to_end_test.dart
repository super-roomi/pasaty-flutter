import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/Util/child_location_ui.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_trip_progress_widget.dart';
import 'package:mockup/l10n/app_localizations.dart';
import 'package:mockup/services/socket_service.dart';

/// Socket payload straight through to rendered text.
///
/// This payload was produced by running the backend's own `snapToLine` +
/// `getStopsForEta` + `buildEstimate` against the restored production
/// database, for route 1 with the bus leaving the school on the afternoon
/// run. Nothing here is hand-written except the expectations.
///
/// The `seconds_away` values are relative to the moment it was generated, so
/// the test rewrites `eta` to fixed offsets from now — otherwise it would
/// start failing the day after it was captured.
const String _capturedPayload = r'''
{"routeid":1,"phase":"afternoon","pace":5.13,"confidence":"normal",
 "generated_at":"2026-08-12T16:25:59.174Z",
 "stops":[
  {"studentid":24,"attendanceid":null,"meters_away":202,"seconds_away":39,
   "eta":"2026-08-12T16:26:38.174Z"},
  {"studentid":23,"attendanceid":null,"meters_away":272,"seconds_away":53,
   "eta":"2026-08-12T16:26:52.174Z"},
  {"studentid":2,"attendanceid":null,"meters_away":565,"seconds_away":110,
   "eta":"2026-08-12T16:27:49.174Z"}]}
''';

void main() {
  testWidgets('a real afternoon payload becomes the parent\'s arrival lines', (
    tester,
  ) async {
    final raw = Map<String, dynamic>.from(
      jsonDecode(_capturedPayload) as Map,
    );

    // Re-base the timestamps so the assertions are about the logic, not about
    // when the fixture was captured.
    final now = DateTime.now().toUtc();
    final offsets = {24: 39, 23: 53, 2: 110};
    raw['generated_at'] = now.toIso8601String();
    raw['stops'] = [
      for (final s in (raw['stops'] as List))
        {
          ...Map<String, dynamic>.from(s as Map),
          'eta': now
              .add(Duration(seconds: offsets[s['studentid'] as int]!))
              .toIso8601String(),
        },
    ];

    final eta = RouteEta.fromJson(raw);
    expect(eta.phase, 'afternoon');
    expect(eta.lowConfidence, isFalse);

    // The next arrival is the nearest stop: student 24, 202 m from the bus.
    final next = eta.byStudent[24]!;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrTripProgressWidget(
              afternoon: eta.phase == 'afternoon',
              eta: TripEta(
                arrival: next.eta,
                metersAway: next.metersAway,
                approximate: eta.lowConfidence,
              ),
              children: const [
                TripProgressChild(
                  name: 'ibrahim',
                  location: ChildLocation.onBus,
                ),
                TripProgressChild(name: 'meran', location: ChildLocation.onBus),
              ],
            ),
          ),
        ),
      ),
    );

    // The bus has just left the school: the nearest stop is seconds away, so
    // a countdown would be noise.
    expect(find.text('Arriving home now'), findsOneWidget);

    // Push the arrival out and the same payload reads as a single figure with
    // its distance.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrTripProgressWidget(
              afternoon: true,
              eta: TripEta(
                arrival: DateTime.now().add(const Duration(minutes: 4)),
                metersAway: next.metersAway,
              ),
              children: const [
                TripProgressChild(
                  name: 'ibrahim',
                  location: ChildLocation.onBus,
                ),
                TripProgressChild(name: 'meran', location: ChildLocation.onBus),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('4'), findsOneWidget);
    expect(find.text('until home'), findsOneWidget);
    expect(find.text('202 m away'), findsOneWidget);
  });
}
