import 'package:latlong2/latlong.dart';

import 'api_client.dart';

/// One stop on a route. `type` is 'student' or 'school'.
class RouteWaypoint {
  final int id;
  final String? name;
  final LatLng position;
  final int sortNumber;
  final String type;
  final int? studentId;

  const RouteWaypoint({
    required this.id,
    required this.name,
    required this.position,
    required this.sortNumber,
    required this.type,
    this.studentId,
  });

  bool get isSchool => type == 'school';

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      id: json['id'] as int,
      name: json['name'] as String?,
      // Stored as separate numeric columns; either may arrive as int or double.
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      sortNumber: (json['sort_number'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? '') as String,
      studentId: json['studentid'] as int?,
    );
  }
}

/// A GeoJSON LineString's `coordinates` as map points.
///
/// GeoJSON is [longitude, latitude]; LatLng is (latitude, longitude), so the
/// pair has to be swapped. Both the morning and the afternoon line go through
/// here so the swap cannot be got right in one and wrong in the other — a
/// swapped pair does not throw, it just draws the route somewhere else on
/// Earth. Anything that is not a LineString (`null`, or a field an older
/// server never sent) yields an empty list.
List<LatLng> _lineFromGeoJson(Object? geo) {
  final coords = geo is Map<String, dynamic> ? geo['coordinates'] : null;
  return <LatLng>[
    if (coords is List)
      for (final c in coords)
        if (c is List && c.length >= 2)
          LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
  ];
}

/// A driver's route: the drawn line plus its stops.
class DriverRouteMap {
  final int routeId;
  final String name;

  /// The generated driving line for the morning run, start → school. Empty
  /// when the admin has not run route generation yet — the map then shows
  /// stops only, with no path drawn.
  final List<LatLng> line;

  /// The afternoon run's own line, school → start.
  ///
  /// Empty until an admin regenerates the route: the server only started
  /// drawing the afternoon separately once roads turned out not to be
  /// symmetric — one-way streets and turn restrictions mean the way back is
  /// often a different road.
  final List<LatLng> afternoonLine;

  final List<RouteWaypoint> waypoints;

  const DriverRouteMap({
    required this.routeId,
    required this.name,
    required this.line,
    required this.afternoonLine,
    required this.waypoints,
  });

  /// The line actually driven during this phase.
  ///
  /// [afternoonLine] already runs school → start, so it is never reversed.
  /// With no afternoon line the morning one stands in, which is exactly what
  /// the app drew before: a polyline renders identically whichever way round
  /// its points run, so the fallback needs no reversal — only the road it
  /// follows can be wrong, which is the whole reason for the separate line.
  List<LatLng> lineFor({required bool afternoon}) =>
      afternoon && afternoonLine.length > 1 ? afternoonLine : line;

  /// Everything that needs to be visible, for fitting the camera.
  List<LatLng> pointsFor({required bool afternoon}) => [
    ...lineFor(afternoon: afternoon),
    ...waypoints.map((w) => w.position),
  ];

  factory DriverRouteMap.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>;

    final waypoints =
        (json['waypoints'] as List? ?? [])
            .map(
              (e) =>
                  RouteWaypoint.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList()
          ..sort((a, b) => a.sortNumber.compareTo(b.sortNumber));

    return DriverRouteMap(
      routeId: route['id'] as int,
      name: (route['name'] ?? '') as String,
      line: _lineFromGeoJson(route['geo']),
      afternoonLine: _lineFromGeoJson(route['afternoon_geo']),
      waypoints: waypoints,
    );
  }
}

class RouteService {
  /// Driver role only: the caller must be the route's assigned driver.
  static Future<DriverRouteMap> getDriverRoute(int routeId) async {
    final body = await ApiClient.get('/v1/routes/driver/route/$routeId');
    return DriverRouteMap.fromJson(body);
  }
}
