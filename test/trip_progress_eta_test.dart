import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/Util/child_location_ui.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_trip_progress_widget.dart';
import 'package:mockup/l10n/app_localizations.dart';

/// The single arrival estimate a parent reads while a run is under way.
///
/// One figure for the whole trip — the next arrival — not a line per child:
/// siblings ride the same bus to the same school, so the number that matters
/// is when the bus next stops, with the distance left to that stop alongside.
Future<void> _pump(
  WidgetTester tester, {
  required bool afternoon,
  TripEta? eta,
  bool awaitingFirst = false,
  int childCount = 2,
  bool absent = false,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PrTripProgressWidget(
            afternoon: afternoon,
            awaitingFirstEstimate: awaitingFirst,
            eta: eta,
            children: [
              for (var i = 0; i < childCount; i++)
                TripProgressChild(
                  name: ['ibrahim', 'meran'][i % 2],
                  location: ChildLocation.atHome,
                  absent: absent,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

TripEta _eta({
  required Duration arrival,
  int meters = 500,
  bool approximate = false,
  bool stale = false,
  int staleMinutes = 0,
}) {
  return TripEta(
    arrival: DateTime.now().add(arrival),
    metersAway: meters,
    approximate: approximate,
    stale: stale,
    staleMinutes: staleMinutes,
  );
}

void main() {
  group('arrival estimate', () {
    testWidgets('two children share one figure, not one each', (tester) async {
      await _pump(
        tester,
        afternoon: true,
        childCount: 2,
        eta: _eta(arrival: const Duration(minutes: 16)),
      );
      // Both names render, but the arrival figure appears exactly once.
      expect(find.text('ibrahim'), findsOneWidget);
      expect(find.text('meran'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('until home'), findsOneWidget);
    });

    testWidgets('shows a single ceil-minute figure and the distance', (
      tester,
    ) async {
      await _pump(
        tester,
        afternoon: true,
        eta: _eta(arrival: const Duration(minutes: 8, seconds: 5), meters: 202),
      );
      expect(find.text('9'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(find.text('202 m away'), findsOneWidget);
      // The absolute arrival clock sits beneath the countdown.
      expect(find.textContaining('Arrives by'), findsOneWidget);
    });

    testWidgets('distance over a kilometre reads in km', (tester) async {
      await _pump(
        tester,
        afternoon: false,
        eta: _eta(arrival: const Duration(minutes: 12), meters: 2340),
      );
      expect(find.text('2.3 km'), findsOneWidget);
    });

    testWidgets('morning speaks about pickup, afternoon about home', (
      tester,
    ) async {
      await _pump(
        tester,
        afternoon: false,
        eta: _eta(arrival: const Duration(minutes: 16)),
      );
      expect(find.text('until pickup'), findsOneWidget);

      await _pump(
        tester,
        afternoon: true,
        eta: _eta(arrival: const Duration(minutes: 16)),
      );
      expect(find.text('until home'), findsOneWidget);
    });

    testWidgets('a stop under a minute away still shows a number', (
      tester,
    ) async {
      await _pump(
        tester,
        afternoon: true,
        eta: _eta(arrival: const Duration(seconds: 20)),
      );
      // The figure is the thing a parent is looking for; it must not be
      // swapped for prose exactly when the bus is closest.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
    });

    testWidgets('an overdue estimate holds at one, never negative', (
      tester,
    ) async {
      await _pump(
        tester,
        afternoon: true,
        eta: _eta(arrival: const Duration(minutes: -4)),
      );
      // ceil() on a past arrival is negative, so without the floor this read
      // "-4 min".
      expect(find.text('1'), findsOneWidget);
      expect(find.text('-4'), findsNothing);
    });

    testWidgets('a shaky estimate is marked with ~ rather than hidden', (
      tester,
    ) async {
      await _pump(
        tester,
        afternoon: true,
        eta: _eta(arrival: const Duration(minutes: 16), approximate: true),
      );
      expect(find.text('~16'), findsOneWidget);
    });

    testWidgets('a stale estimate keeps the last figure and says so', (
      tester,
    ) async {
      await _pump(
        tester,
        afternoon: true,
        eta: _eta(
          arrival: const Duration(minutes: 2),
          stale: true,
          staleMinutes: 8,
        ),
      );
      // Reports what was known at broadcast, not what the live clock says.
      expect(find.text('Last known 8 min, not updating'), findsOneWidget);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('before the first broadcast it says it is waiting', (
      tester,
    ) async {
      await _pump(tester, afternoon: true, eta: null, awaitingFirst: true);
      expect(find.text('Waiting for update'), findsOneWidget);
    });

    testWidgets('once estimates flow, no outstanding stop shows nothing', (
      tester,
    ) async {
      // Everyone boarded or dropped off: the tracks already say so.
      await _pump(tester, afternoon: true, eta: null, awaitingFirst: false);
      expect(find.text('Waiting for update'), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
      expect(find.byIcon(Icons.near_me_outlined), findsNothing);
    });

    testWidgets('renders in Arabic', (tester) async {
      await _pump(
        tester,
        afternoon: true,
        locale: const Locale('ar'),
        eta: _eta(arrival: const Duration(minutes: 16)),
      );
      expect(find.text('حتى الوصول إلى المنزل'), findsOneWidget);
    });
  });
}
