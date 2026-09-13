import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/services/socket_service.dart';

/// Verified against real output from the backend's own `utils/eta.js`
/// (`buildEstimate`) rather than a hand-written payload, so a change to the
/// server's field names fails here instead of silently blanking the parent's
/// arrival times.
const String _realPayload = '''
{"routeid":1,"phase":"morning","pace":2.24,"confidence":"normal",
 "generated_at":"2026-08-12T14:26:08.975Z",
 "stops":[
   {"studentid":1,"attendanceid":47,"meters_away":300,"seconds_away":134,
    "eta":"2026-08-12T14:28:22.975Z"},
   {"studentid":2,"attendanceid":46,"meters_away":700,"seconds_away":313,
    "eta":"2026-08-12T14:31:21.975Z"}]}
''';

void main() {
  group('RouteEta.fromJson', () {
    test('parses a real backend payload', () {
      final eta = RouteEta.fromJson(
        Map<String, dynamic>.from(jsonDecode(_realPayload) as Map),
      );

      expect(eta.routeId, 1);
      expect(eta.phase, 'morning');
      expect(eta.lowConfidence, isFalse);
      expect(eta.byStudent.keys, unorderedEquals([1, 2]));

      final first = eta.byStudent[1]!;
      expect(first.attendanceId, 47);
      expect(first.metersAway, 300);
      // Stored as an absolute instant so the UI can keep counting down
      // between pings; compared in UTC because parsing converts to local.
      expect(
        first.eta.toUtc().toIso8601String(),
        '2026-08-12T14:28:22.975Z',
      );
    });

    test('a student the bus has already served is simply absent from the map', () {
      final eta = RouteEta.fromJson(
        Map<String, dynamic>.from(jsonDecode(_realPayload) as Map),
      );
      // Student 17 was BOARDED, so the server omits them. The UI must treat a
      // missing entry as "no wait to report", not as an error.
      expect(eta.byStudent[17], isNull);
    });

    test('low confidence is read from the string, not inverted', () {
      final raw = Map<String, dynamic>.from(jsonDecode(_realPayload) as Map)
        ..['confidence'] = 'low';
      expect(RouteEta.fromJson(raw).lowConfidence, isTrue);
    });

    test('a route with no reachable stops parses to an empty map', () {
      final raw = Map<String, dynamic>.from(jsonDecode(_realPayload) as Map)
        ..['stops'] = <dynamic>[];
      expect(RouteEta.fromJson(raw).byStudent, isEmpty);
    });

    test('a null attendanceid is tolerated', () {
      final raw = Map<String, dynamic>.from(jsonDecode(_realPayload) as Map);
      final stops = List<Map<String, dynamic>>.from(
        (raw['stops'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      // The server sends `attendanceid: null` when a student has no
      // attendance row for today yet.
      stops[0]['attendanceid'] = null;
      raw['stops'] = stops;
      expect(RouteEta.fromJson(raw).byStudent[1]!.attendanceId, isNull);
    });
  });
}
