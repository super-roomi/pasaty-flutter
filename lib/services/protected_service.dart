import 'api_client.dart';

/// Profile returned by GET /v1/protected/profile.
class Profile {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.createdAt,
  });

  String get name => lastName.isEmpty ? firstName : '$firstName $lastName';

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      firstName: (json['first_name'] ?? '') as String,
      lastName: (json['last_name'] ?? '') as String,
      phone: json['phone'] as String,
      createdAt: json['createdat'] != null
          ? DateTime.tryParse(json['createdat'].toString())
          : null,
    );
  }
}

/// One row of GET /v1/protected/students (parent's own children).
/// `status` here is the assignment status from the students table
/// ('unassigned'...), not the live attendance status.
class Student {
  final int id;
  final String firstName;
  final String status;
  final int? routeId;

  const Student({
    required this.id,
    required this.firstName,
    required this.status,
    this.routeId,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      firstName: (json['first_name'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      routeId: json['routeid'] as int?,
    );
  }
}

/// One row of GET /v1/protected/myroutes (routes assigned to the driver).
class DriverRoute {
  final int id;
  final String name;

  const DriverRoute({required this.id, required this.name});

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    return DriverRoute(id: json['id'] as int, name: json['name'] as String);
  }
}

/// Client for the /v1/protected/* routes, which require a Bearer token.
class ProtectedService {
  static Future<Profile> getProfile() async {
    final body = await ApiClient.get('/v1/protected/profile');
    return Profile.fromJson(body['user'] as Map<String, dynamic>);
  }

  /// Parent role only. Backend answers 404 when the parent has no
  /// students; that is returned as an empty list, not an error.
  static Future<List<Student>> getStudents() async {
    try {
      final body = await ApiClient.get('/v1/protected/students');
      return (body['students'] as List)
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// Driver role only. 404 (no routes assigned) comes back as [].
  static Future<List<DriverRoute>> getMyRoutes() async {
    try {
      final body = await ApiClient.get('/v1/protected/myroutes');
      return (body['routes'] as List)
          .map((e) => DriverRoute.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }
}
