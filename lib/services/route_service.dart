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

/// A driver's route: the drawn line plus its stops.
class DriverRouteMap {
  final int routeId;
  final String name;

  /// The generated driving line. Empty when the admin has not run route
  /// generation yet — the map then shows stops only, with no path drawn.
  final List<LatLng> line;

  final List<RouteWaypoint> waypoints;

  const DriverRouteMap({
    required this.routeId,
    required this.name,
    required this.line,
    required this.waypoints,
  });

  bool get hasLine => line.length > 1;

  /// Everything that needs to be visible, for fitting the camera.
  List<LatLng> get allPoints => [...line, ...waypoints.map((w) => w.position)];

  factory DriverRouteMap.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>;

    // routes.geo is a GeoJSON LineString. GeoJSON is [longitude, latitude];
    // LatLng is (latitude, longitude), so the pair has to be swapped.
    final geo = route['geo'];
    final coords = geo is Map<String, dynamic> ? geo['coordinates'] : null;
    final line = <LatLng>[
      if (coords is List)
        for (final c in coords)
          if (c is List && c.length >= 2)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
    ];

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
      line: line,
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
