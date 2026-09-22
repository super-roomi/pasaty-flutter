import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/services/route_service.dart';

/// Which road line the driver map draws, morning versus afternoon.
///
/// The afternoon visits the morning's stops in reverse, and the server used to
/// store only the morning line — the afternoon was drawn by reading it
/// backwards. Roads are not symmetric: one-way streets, turn restrictions and
/// divided roads mean the way back is often a different road, so a reversed
/// morning line could point the driver the wrong way down a one-way street.
///
/// The server now draws the afternoon separately and sends it as
/// `afternoon_geo`, already in driving order (school → start). It must never
/// be reversed, and it is null on any route nobody has regenerated since —
/// which is why the morning-line fallback has to stay.

/// The response shape of GET /v1/routes/driver/route/:routeid.
///
/// Coordinates are GeoJSON [longitude, latitude]. Morning runs east along
/// 35.5800; the afternoon detours north to 35.5815 on the way back, standing
/// in for the one-way street that motivated the whole change — if the app
/// reversed the morning line instead, it would never touch 35.5815.
Map<String, dynamic> payload({Object? afternoonGeo = _absent}) => {
  'route': {
    'id': 17,
    'name': 'Baxtiari Route',
    'geo': {
      'type': 'LineString',
      'coordinates': [
        [45.4500, 35.5800],
        [45.4600, 35.5800],
      ],
    },
    'distance': 904.2,
    'duration': 301.4,
    if (afternoonGeo != _absent) 'afternoon_geo': afternoonGeo,
    'afternoon_distance': 1238.0,
    'afternoon_duration': 412.7,
  },
  'waypoints': [
    {
      'id': 101,
      'name': 'Start',
      'latitude': 35.5800,
      'longitude': 45.4500,
      'sort_number': 0,
      'type': 'start',
      'station': 0,
      'afternoon_station': 1238.0,
      'leg_distance': null,
      'afternoon_leg_distance': 271.4,
    },
    {
      'id': 104,
      'name': 'School',
      'latitude': 35.5800,
      'longitude': 45.4600,
      'sort_number': 3,
      'type': 'school',
      'station': 904.2,
      // The school is exactly 0 metres along the afternoon line, and
      // jsonDecode turns a bare 0 into an int — a `as double` cast here would
      // throw for every route that has been regenerated.
      'afternoon_station': 0,
      'leg_distance': 362.1,
      'afternoon_leg_distance': null,
    },
  ],
};

const _absent = Object();

const _afternoonGeo = {
  'type': 'LineString',
  'coordinates': [
    [45.4600, 35.5800],
    [45.4600, 35.5815],
    [45.4500, 35.5815],
    [45.4500, 35.5800],
  ],
};

void main() {
  test('afternoon draws the server\'s afternoon line, in the order sent', () {
    final route = DriverRouteMap.fromJson(payload(afternoonGeo: _afternoonGeo));
    final line = route.lineFor(afternoon: true);

    expect(line.length, 4);
    // School → start: it begins where the morning ended.
    expect(line.first.latitude, 35.5800);
    expect(line.first.longitude, 45.4600);
    expect(line.last.longitude, 45.4500);
    // The detour the reversed morning line could never produce.
    expect(line.any((p) => p.latitude == 35.5815), isTrue);
  });

  test('afternoon_geo is never reversed', () {
    final route = DriverRouteMap.fromJson(payload(afternoonGeo: _afternoonGeo));
    final line = route.lineFor(afternoon: true);
    final reversed = line.reversed.toList();

    // Guards the one mistake that silently sends the bus the wrong way: the
    // line still has the right points, only walked backwards.
    expect(line.first, isNot(equals(reversed.first)));
    expect(line.first.longitude, 45.4600, reason: 'must start at the school');
  });

  test('morning is untouched even once an afternoon line exists', () {
    final route = DriverRouteMap.fromJson(payload(afternoonGeo: _afternoonGeo));
    final line = route.lineFor(afternoon: false);

    expect(line.length, 2);
    expect(line.first.longitude, 45.4500, reason: 'morning starts at the start');
    expect(line.last.longitude, 45.4600);
  });

  group('falls back to the morning line when there is no afternoon one', () {
    // Each of these is a route the driver still has to be able to see: a null
    // from a server that has the column but has not regenerated this route, a
    // missing key from a server build that predates the column, and a stub
    // line too short to draw.
    final cases = <String, Object?>{
      'null (not regenerated yet)': null,
      'too few coordinates to draw': {
        'type': 'LineString',
        'coordinates': [
          [45.46, 35.58],
        ],
      },
    };

    cases.forEach((name, geo) {
      test(name, () {
        final route = DriverRouteMap.fromJson(payload(afternoonGeo: geo));
        expect(route.afternoonLine.length, lessThan(2));
        expect(route.lineFor(afternoon: true), equals(route.line));
      });
    });

    test('field absent entirely (older server)', () {
      final route = DriverRouteMap.fromJson(payload());
      expect(route.lineFor(afternoon: true), equals(route.line));
      expect(route.lineFor(afternoon: true).length, 2);
    });
  });

  test('coordinates are swapped out of GeoJSON order', () {
    final route = DriverRouteMap.fromJson(payload(afternoonGeo: _afternoonGeo));

    // GeoJSON sends [longitude, latitude]; LatLng takes (latitude, longitude).
    // Getting this backwards does not throw, it draws the route in the wrong
    // hemisphere — so both lines are checked.
    for (final line in [route.line, route.afternoonLine]) {
      for (final p in line) {
        expect(p.latitude, closeTo(35.58, 0.01));
        expect(p.longitude, closeTo(45.45, 0.02));
      }
    }
  });

  test('a school stop with afternoon_station 0 parses', () {
    // jsonDecode yields int for a bare 0. Nothing reads the station fields
    // today, but the payload must not take the map down if that changes.
    final route = DriverRouteMap.fromJson(payload(afternoonGeo: _afternoonGeo));
    expect(route.waypoints.any((w) => w.isSchool), isTrue);
  });

  test('camera points follow the phase', () {
    final route = DriverRouteMap.fromJson(payload(afternoonGeo: _afternoonGeo));

    // Fitting to the morning line in the afternoon would crop the detour.
    expect(
      route.pointsFor(afternoon: true).any((p) => p.latitude == 35.5815),
      isTrue,
    );
    expect(
      route.pointsFor(afternoon: false).any((p) => p.latitude == 35.5815),
      isFalse,
    );
  });

  test('stops stay sorted by sort_number ascending', () {
    // The endpoint has no ORDER BY, so the model sorts. Afternoon travel order
    // is this reversed, which the map and the status page each apply.
    final route = DriverRouteMap.fromJson(payload(afternoonGeo: _afternoonGeo));
    expect(route.waypoints.map((w) => w.sortNumber), [0, 3]);
  });
}
