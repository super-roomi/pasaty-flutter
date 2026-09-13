import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/l10n/app_localizations_ar.dart';
import 'package:mockup/l10n/app_localizations_en.dart';

/// Copy that must not name a day, and counts that must agree with their noun.
///
/// Both bugs here were found on a live run, and the first one twice: the
/// absence confirmation said "today" while booking tomorrow, because only the
/// message was date-aware and the title and button were written for the
/// original today-only version of the feature.
void main() {
  final en = AppLocalizationsEn();
  final ar = AppLocalizationsAr();

  group('absence confirmation names no day of its own', () {
    // The message carries the real day; anything around it that also claims a
    // day can contradict it.
    test('English title and action are day-agnostic', () {
      expect(en.absenceConfirmTitle.toLowerCase(), isNot(contains('today')));
      expect(en.absenceConfirmAction.toLowerCase(), isNot(contains('today')));
      expect(en.absenceNotBookedLabel.toLowerCase(), isNot(contains('today')));
    });

    test('Arabic title and action are day-agnostic', () {
      // اليوم = "today".
      expect(ar.absenceConfirmTitle, isNot(contains('اليوم')));
      expect(ar.absenceConfirmAction, isNot(contains('اليوم')));
      expect(ar.absenceNotBookedLabel, isNot(contains('اليوم')));
    });

    test('the message is still the thing that names the day', () {
      expect(en.absenceConfirmDayMessage('child1', 'Mon, Sep 14'),
          contains('Mon, Sep 14'));
    });
  });

  group('driver counts agree with their noun', () {
    test('one student is singular', () {
      expect(en.dropoffRemaining(1), '1 student still on the bus');
      expect(en.pickupRemaining(1), '1 student to pick up');
    });

    test('several students are plural', () {
      expect(en.dropoffRemaining(3), '3 students still on the bus');
      expect(en.pickupRemaining(4), '4 students to pick up');
    });

    test('none reads as none rather than zero', () {
      expect(en.dropoffRemaining(0), 'No students still on the bus');
      expect(en.pickupRemaining(0), 'No students to pick up');
    });
  });
}
