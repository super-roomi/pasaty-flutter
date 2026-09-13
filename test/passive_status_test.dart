import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/Util/child_location_ui.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_status_passive_widget.dart';
import 'package:mockup/l10n/app_localizations.dart';
import 'package:mockup/services/attendance_service.dart';

/// The quiet card shown between runs.
///
/// It used to read "All home" unconditionally, which contradicted the roster
/// underneath the moment a morning run finished: the chips said "In school"
/// while the headline said everyone was at home.
Future<void> _pump(WidgetTester tester, {required bool atSchool}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PrStatusPagePassive(atSchool: atSchool)),
    ),
  );
}

void main() {
  group('resting place after a run', () {
    test('a completed morning run leaves children at school', () {
      // ARRIVED is the terminal morning status; this mapping is what the
      // passive card derives "at school" from.
      expect(
        childLocationFor(phase: 'morning', status: AttendanceStatus.arrived),
        ChildLocation.inSchool,
      );
    });

    test('a completed afternoon run leaves children at home', () {
      expect(
        childLocationFor(
          phase: 'afternoon',
          status: AttendanceStatus.droppedOff,
        ),
        ChildLocation.atHome,
      );
    });

    test('an absent child is at home regardless of phase', () {
      for (final phase in ['morning', 'afternoon']) {
        expect(
          childLocationFor(phase: phase, status: AttendanceStatus.absent),
          ChildLocation.atHome,
        );
      }
    });

    testWidgets('the card says school, with a school icon', (tester) async {
      await _pump(tester, atSchool: true);
      expect(find.text('All at school'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.text('All home'), findsNothing);
    });

    testWidgets('and falls back to home between school days', (tester) async {
      await _pump(tester, atSchool: false);
      expect(find.text('All home'), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.text('All at school'), findsNothing);
    });
  });
}
