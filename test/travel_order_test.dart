import 'package:flutter_test/flutter_test.dart';

/// Ordering the driver's roster by where the bus actually goes.
///
/// The server returns the afternoon roster ordered by student id, which bears
/// no relation to the route. On route 1 that is:
///
///   student id   1   2  17  23  24
///   route stop   2   3   1   4   5
///
/// Driven in that order the bus doubles back twice, and the map ticks stops
/// off in what looks like a random sequence — the reported bug.
///
/// This mirrors `_inTravelOrder` in dv_status_page.dart. It is duplicated
/// rather than exported because the page's copy is bound to widget state;
/// if the two drift, this test is the one that says so.
List<int> travelOrder(
  List<int> studentIds,
  Map<int, int> stopOrder, {
  required bool afternoon,
}) {
  if (stopOrder.isEmpty) return studentIds;
  final ordered = [...studentIds];
  ordered.sort((a, b) {
    final sa = stopOrder[a];
    final sb = stopOrder[b];
    if (sa == null && sb == null) return 0;
    if (sa == null) return 1;
    if (sb == null) return -1;
    return afternoon ? sb.compareTo(sa) : sa.compareTo(sb);
  });
  return ordered;
}

void main() {
  // Route 1 as it exists in the database: waypoint sort_number by student.
  const stops = {17: 1, 1: 2, 2: 3, 23: 4, 24: 5};

  // The order the server actually sends for the afternoon (ORDER BY s.id).
  const asSentByServer = [1, 2, 17, 23, 24];

  group('travel order', () {
    test('morning follows the waypoints', () {
      expect(
        travelOrder(asSentByServer, stops, afternoon: false),
        [17, 1, 2, 23, 24],
      );
    });

    test('afternoon is the exact reverse, not the server order', () {
      final result = travelOrder(asSentByServer, stops, afternoon: true);
      expect(result, [24, 23, 2, 1, 17]);
      // The bug: without reordering the driver is sent 2, 3, 1, 4, 5.
      expect(result, isNot(asSentByServer));
    });

    test('afternoon is the morning order reversed', () {
      expect(
        travelOrder(asSentByServer, stops, afternoon: true),
        travelOrder(asSentByServer, stops, afternoon: false).reversed.toList(),
      );
    });

    test('a student with no waypoint is kept, at the end', () {
      // Losing them from the roster would lose a child; they go last so the
      // driver still sees them.
      final result = travelOrder([...asSentByServer, 99], stops,
          afternoon: true);
      expect(result.last, 99);
      expect(result.length, 6);
    });

    test('without waypoint data the server order is left alone', () {
      expect(travelOrder(asSentByServer, const {}, afternoon: true),
          asSentByServer);
    });
  });
}
