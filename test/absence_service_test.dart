import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockup/services/absence_service.dart';
import 'package:mockup/services/api_client.dart';
import 'package:mockup/services/auth_session.dart';

/// The absence client, against the contract in the mobile spec.
///
/// The two things worth pinning here are both easy to get quietly wrong:
/// declaring "today" must send no date at all, and the per-day states must
/// not collapse into a plain success/failure — a range can be partly booked,
/// and `existing` is a success.
void main() {
  setUp(() => AuthSession.instance.accessToken = 'test-token');

  tearDown(() {
    ApiClient.resetForTesting();
    AuthSession.instance.accessToken = null;
  });

  /// Captures the one request the call makes.
  ({List<http.Request> sent}) capture(String body, {int status = 200}) {
    final sent = <http.Request>[];
    ApiClient.resetForTesting(
      withClient: MockClient((request) async {
        sent.add(request);
        return http.Response(
          body,
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    return (sent: sent);
  }

  group('declaring today', () {
    test('sends no date, so the server decides the calendar day', () async {
      final captured = capture(
        jsonEncode({
          'studentid': 41,
          'days': [
            {'date': '2026-09-01', 'state': 'planned'},
          ],
        }),
      );

      await AbsenceService.declareToday(41);

      // The whole point: a phone in the wrong timezone that computes today
      // itself books the neighbouring morning, and nothing surfaces the
      // mistake until a child is skipped.
      final body =
          jsonDecode(captured.sent.single.body) as Map<String, dynamic>;
      expect(body, {'studentid': 41});
      expect(body.containsKey('from'), isFalse);
      expect(body.containsKey('to'), isFalse);
    });

    test('reads the booked day back from the response', () async {
      capture(
        jsonEncode({
          'studentid': 41,
          'days': [
            {'date': '2026-09-01', 'state': 'planned'},
          ],
        }),
      );

      final result = await AbsenceService.declareToday(41);
      expect(result.days.single.date, '2026-09-01');
      expect(result.days.single.state, AbsenceDayState.planned);
    });
  });

  group('declaring a range', () {
    test('sends plain calendar labels, never timestamps', () async {
      final captured = capture(
        jsonEncode({'studentid': 7, 'days': const []}),
      );

      await AbsenceService.declareRange(
        studentId: 7,
        from: DateTime(2026, 9, 1, 23, 30),
        to: DateTime(2026, 9, 3, 4, 15),
      );

      expect(jsonDecode(captured.sent.single.body), {
        'studentid': 7,
        'from': '2026-09-01',
        'to': '2026-09-03',
      });
    });

    test('a partly-honoured range reports both halves', () async {
      capture(
        jsonEncode({
          'studentid': 41,
          'days': [
            {'date': '2026-09-01', 'state': 'too_late', 'reason': 'already_boarded'},
            {'date': '2026-09-02', 'state': 'planned'},
            {'date': '2026-09-03', 'state': 'existing'},
          ],
        }),
      );

      final result = await AbsenceService.declareRange(
        studentId: 41,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 3),
      );

      // `existing` counts as booked — re-tapping is safe and must not read
      // as a failure.
      expect(result.booked.map((d) => d.date), ['2026-09-02', '2026-09-03']);
      expect(result.refused.single.reason, AbsenceRefusal.alreadyBoarded);
    });

    test('a live application is flagged so the parent is told', () async {
      capture(
        jsonEncode({
          'studentid': 41,
          'days': [
            {'date': '2026-09-01', 'state': 'live'},
          ],
        }),
      );

      final result = await AbsenceService.declareToday(41);
      expect(result.anyLive, isTrue);
      expect(result.booked, hasLength(1));
    });

    test('an unknown state is treated as refused, not as success', () async {
      capture(
        jsonEncode({
          'studentid': 41,
          'days': [
            {'date': '2026-09-01', 'state': 'something_new'},
          ],
        }),
      );

      final result = await AbsenceService.declareToday(41);
      expect(result.days.single.state, AbsenceDayState.tooLate);
      expect(result.booked, isEmpty);
    });
  });

  group('failures', () {
    test('409 surfaces as a conflict the UI can localize', () async {
      capture(
        jsonEncode({'message': 'Ahmad is already on the bus.'}),
        status: 409,
      );

      await expectLater(
        AbsenceService.declareToday(41),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.conflict,
          ),
        ),
      );
    });

    test('cancelling after the run started is a conflict', () async {
      capture(jsonEncode({'message': 'Run already started'}), status: 409);

      await expectLater(
        AbsenceService.cancel(studentId: 41, date: '2026-09-01'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.conflict,
          ),
        ),
      );
    });
  });

  group('cancelling', () {
    test('identifies the day in the body, not the path', () async {
      final captured = capture(
        jsonEncode({
          'studentid': 41,
          'date': '2026-09-01',
          'cancelled': true,
        }),
      );

      await AbsenceService.cancel(studentId: 41, date: '2026-09-01');

      final request = captured.sent.single;
      expect(request.method, 'DELETE');
      expect(request.url.path, '/v1/protected/absence');
      expect(request.url.query, isEmpty);
      expect(jsonDecode(request.body), {
        'studentid': 41,
        'date': '2026-09-01',
      });
    });
  });

  group('counting days from the server\'s today', () {
    test('walks forward across a month boundary', () {
      expect(AbsenceWindow.addDays('2026-08-29', 0), '2026-08-29');
      expect(AbsenceWindow.addDays('2026-08-29', 1), '2026-08-30');
      expect(AbsenceWindow.addDays('2026-08-31', 1), '2026-09-01');
    });

    test('walks forward across a year boundary', () {
      expect(AbsenceWindow.addDays('2026-12-31', 1), '2027-01-01');
    });

    test('handles a leap day', () {
      expect(AbsenceWindow.addDays('2028-02-28', 1), '2028-02-29');
      expect(AbsenceWindow.addDays('2028-02-29', 1), '2028-03-01');
    });

    test('a malformed label is returned untouched rather than guessed at', () {
      expect(AbsenceWindow.addDays('not-a-date', 1), 'not-a-date');
      expect(AbsenceWindow.addDays('', 1), '');
    });
  });

  group('listing', () {
    test('keeps the server date string untouched', () async {
      capture(
        jsonEncode({
          'from': '2026-08-28',
          'to': '2026-09-27',
          'absences': [
            {
              'id': 12,
              'studentid': 41,
              'date': '2026-09-01',
              'student_name': 'Ahmad',
              'createdat': '2026-08-28T09:14:02.881Z',
            },
          ],
        }),
      );

      final window = await AbsenceService.upcoming();

      // Held as a label, never a DateTime: parsing would re-read a
      // school-timezone day in the device's zone and can shift it by one.
      expect(window.absences.single.date, '2026-09-01');
      expect(window.absences.single.studentName, 'Ahmad');
      expect(window.absences.single.studentId, 41);

      // The school's own calendar day, which every offered morning is
      // counted from.
      expect(window.today, '2026-08-28');
    });

    test('omits bounds entirely when none are given', () async {
      final captured = capture(jsonEncode({'absences': const []}));

      await AbsenceService.upcoming();

      expect(captured.sent.single.url.query, isEmpty);
    });

    test('sends both bounds as calendar labels when given', () async {
      final captured = capture(jsonEncode({'absences': const []}));

      await AbsenceService.upcoming(
        from: DateTime(2026, 8, 28),
        to: DateTime(2026, 9, 27),
      );

      final query = captured.sent.single.url.queryParameters;
      expect(query, {'from': '2026-08-28', 'to': '2026-09-27'});
    });

    test('an empty listing is not an error', () async {
      capture(jsonEncode({'from': '2026-08-28', 'absences': const []}));
      expect((await AbsenceService.upcoming()).absences, isEmpty);
    });
  });
}
