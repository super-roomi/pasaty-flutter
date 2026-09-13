import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/Util/child_location_ui.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_status_passive_widget.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_trip_progress_widget.dart';
import 'package:mockup/l10n/app_localizations.dart';

/// Renders the parent's card to a PNG so the arrival line can be looked at
/// rather than inferred from assertions.
///
/// Run with: flutter test --update-goldens test/eta_golden_test.dart
Future<void> _loadFonts() async {
  final loader = FontLoader('NotoSansArabic')
    ..addFont(
      File('assets/NotoSansArabic-Regular.ttf').readAsBytes().then(
        (b) => ByteData.view(b.buffer),
      ),
    );
  await loader.load();
}

Widget _card({
  required bool afternoon,
  required List<TripProgressChild> kids,
  TripEta? eta,
}) {
  return MediaQuery(
    data: const MediaQueryData(size: Size(420, 700)),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'NotoSansArabic'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: SingleChildScrollView(
            child: PrTripProgressWidget(
              afternoon: afternoon,
              children: kids,
              eta: eta,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  // The values here are the ones the live socket test actually produced from
  // the backend's estimator: meran 202 m from the bus, zain 1474 m.
  testWidgets('afternoon — time until each child gets home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    // Frozen so the countdown and the "Arrives by" clock are reproducible.
    final now = DateTime(2026, 9, 11, 7, 42);
    await withClock(Clock.fixed(now), () async {
      await tester.pumpWidget(
        _card(
          afternoon: true,
          // The next stop the live socket test actually produced: meran 202 m
          // from the bus, ~4 min out.
          eta: TripEta(
            arrival: now.add(const Duration(minutes: 4)),
            metersAway: 202,
          ),
          kids: const [
            TripProgressChild(name: 'meran', location: ChildLocation.onBus),
            TripProgressChild(name: 'zain', location: ChildLocation.onBus),
          ],
        ),
      );
      await tester.pumpAndSettle();
    });
    await expectLater(
      find.byType(PrTripProgressWidget),
      matchesGoldenFile('goldens/eta_afternoon.png'),
    );
  });

  testWidgets('morning — time until the bus reaches each child', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    final now = DateTime(2026, 9, 11, 7, 42);
    await withClock(Clock.fixed(now), () async {
      await tester.pumpWidget(
        _card(
          afternoon: false,
          // Low confidence: the figure is marked with ~ rather than hidden.
          eta: TripEta(
            arrival: now.add(const Duration(minutes: 6)),
            metersAway: 1474,
            approximate: true,
          ),
          kids: const [
            TripProgressChild(name: 'ibrahim', location: ChildLocation.atHome),
            TripProgressChild(name: 'meran', location: ChildLocation.atHome),
          ],
        ),
      );
      await tester.pumpAndSettle();
    });
    await expectLater(
      find.byType(PrTripProgressWidget),
      matchesGoldenFile('goldens/eta_morning.png'),
    );
  });

  // The bug: this card read "All home" even straight after a morning run,
  // contradicting the roster below it.
  testWidgets('passive card — after the morning run, children are at school', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 320));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(420, 320)),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'NotoSansArabic'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            backgroundColor: Color(0xFFFBF9FB),
            body: Center(child: PrStatusPagePassive(atSchool: true)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PrStatusPagePassive),
      matchesGoldenFile('goldens/passive_at_school.png'),
    );
  });
}
