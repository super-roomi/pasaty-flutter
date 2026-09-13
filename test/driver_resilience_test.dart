import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockup/services/api_client.dart';
import 'package:mockup/services/attendance_service.dart';
import 'package:mockup/services/auth_session.dart';

/// Which write failures are worth repeating.
///
/// Mirrors `_worthRetrying` in dv_status_page.dart, duplicated here for the
/// same reason `outstanding()` is in driver_absent_queue_test: the page's copy
/// is a few lines inside a State class, and what matters is that the rule is
/// pinned. Retrying a 409 would delay telling the driver the run is in the
/// wrong phase; not retrying a timeout makes them tap again while driving.
bool worthRetrying(Object error) {
  if (error is! ApiException) return true;
  return error.kind == ApiErrorKind.network ||
      error.kind == ApiErrorKind.badResponse ||
      error.kind == ApiErrorKind.server;
}

void main() {
  group('retrying an attendance write', () {
    test('no answer at all is retried', () {
      // A socket hang-up or timeout never reaches ApiException.
      expect(worthRetrying(Exception('SocketException: no route to host')), isTrue);
    });

    test('a server fault or proxy page is retried', () {
      expect(worthRetrying(ApiException('boom', statusCode: 500)), isTrue);
      expect(worthRetrying(ApiException('bad gateway', statusCode: 502)), isTrue);
      expect(
        worthRetrying(
          ApiException('html', statusCode: 200, kind: ApiErrorKind.badResponse),
        ),
        isTrue,
      );
    });

    test('a real verdict from the server is not retried', () {
      // These are answers, not failures to be asked again.
      expect(worthRetrying(ApiException('wrong phase', statusCode: 409)), isFalse);
      expect(worthRetrying(ApiException('not yours', statusCode: 403)), isFalse);
      expect(worthRetrying(ApiException('unknown id', statusCode: 404)), isFalse);
    });
  });

  group('loading history over a flaky link', () {
    setUp(() => AuthSession.instance.accessToken = 'test-token');
    tearDown(() {
      ApiClient.resetForTesting();
      AuthSession.instance.accessToken = null;
    });

    /// Answers per requested date: a run, no run, or a failure.
    void serve(Map<String, int> statusByDate) {
      ApiClient.resetForTesting(
        withClient: MockClient((request) async {
          final date = (jsonDecode(request.body) as Map)['date'] as String;
          final status = statusByDate[date] ?? 200;
          if (status != 200) return http.Response('{}', status);
          // An empty roster is how the backend says "no run that day".
          final students = statusByDate.containsKey(date) && status == 200
              ? [
                  {
                    'attendanceid': 1,
                    'id': 1,
                    'first_name': 'ibrahim',
                    'parent_name': 'Test',
                    'morning_status': 'ARRIVED',
                  },
                ]
              : const [];
          return http.Response(
            jsonEncode({'students': students}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
    }

    test('a day that failed is counted, not silently dropped', () async {
      // The regression: a failed probe and a day with no run both vanish from
      // the list, so the driver read an incomplete history as a complete one.
      serve({
        '2026-09-13': 200,
        '2026-09-12': 500,
        '2026-09-11': 200,
      });

      final result = await AttendanceService.loadSessions(
        1,
        endDay: DateTime(2026, 9, 13),
        days: 3,
      );

      expect(result.sessions, hasLength(2));
      expect(result.unreadableDays, 1);
    });

    test('a clean window reports nothing unreadable', () async {
      serve({'2026-09-13': 200, '2026-09-12': 200});

      final result = await AttendanceService.loadSessions(
        1,
        endDay: DateTime(2026, 9, 13),
        days: 2,
      );

      expect(result.sessions, hasLength(2));
      expect(result.unreadableDays, 0);
    });

    test('every probe failing is an error, not an empty history', () async {
      serve({'2026-09-13': 500, '2026-09-12': 500});

      await expectLater(
        AttendanceService.loadSessions(
          1,
          endDay: DateTime(2026, 9, 13),
          days: 2,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
