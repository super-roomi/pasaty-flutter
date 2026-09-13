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
  final int? schoolId;

  /// Joined from the `school` table by the backend. Null only when the child
  /// has no school assigned.
  final String? schoolName;

  const Student({
    required this.id,
    required this.firstName,
    required this.status,
    this.routeId,
    this.schoolId,
    this.schoolName,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      firstName: (json['first_name'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      routeId: json['routeid'] as int?,
      schoolId: json['schoolid'] as int?,
      schoolName: json['school_name'] as String?,
    );
  }
}

/// One row of GET /v1/protected/myroutes (routes assigned to the driver).
class DriverRoute {
  final int id;
  final String name;
  final int? schoolId;

  /// Joined from the `school` table by the backend.
  final String? schoolName;

  const DriverRoute({
    required this.id,
    required this.name,
    this.schoolId,
    this.schoolName,
  });

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    return DriverRoute(
      id: json['id'] as int,
      name: json['name'] as String,
      schoolId: json['schoolid'] as int?,
      schoolName: json['school_name'] as String?,
    );
  }
}

/// Today's attendance for one child, from GET /v1/protected/attendance/:id.
///
/// The backend stores the two phases side by side. The afternoon column only
/// becomes non-null once the afternoon run touches the row, so a non-null
/// afternoon status is what tells us which phase reflects "now".
class StudentAttendance {
  /// The attendance row's own id. Live `attendance:updated` events are keyed
  /// by this, so it has to be captured here too: a parent who opens the app
  /// mid-run never sees a roster broadcast, and without this id every
  /// subsequent per-student update has nothing to match against.
  final int attendanceId;

  final int studentId;
  final String? morningStatus;
  final String? afternoonStatus;

  const StudentAttendance({
    required this.attendanceId,
    required this.studentId,
    this.morningStatus,
    this.afternoonStatus,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    return StudentAttendance(
      attendanceId: json['id'] as int,
      studentId: json['studentid'] as int,
      morningStatus: json['morning_status'] as String?,
      afternoonStatus: json['afternoon_status'] as String?,
    );
  }

  String get currentPhase => afternoonStatus != null ? 'afternoon' : 'morning';
  String? get currentStatus => afternoonStatus ?? morningStatus;
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

  /// Parent role only. Today's attendance for one of the parent's children.
  ///
  /// Returns null when no run has touched the child today (the backend
  /// answers 404). Without this the app is push-only: a parent who opens it
  /// after the driver already started sees nothing until the next broadcast.
  static Future<StudentAttendance?> getStudentAttendance(int studentId) async {
    try {
      final body = await ApiClient.get('/v1/protected/attendance/$studentId');
      return StudentAttendance.fromJson(
        body['attendance'] as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
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

  /// Permanently deletes the signed-in user's own account.
  ///
  /// Takes no id — the backend deletes whoever the access token belongs to,
  /// so there is nothing here that could delete the wrong account.
  ///
  /// Throws [ApiException] on failure; the caller must not sign the user out
  /// unless this returns, or a failed delete would look like it worked.
  static Future<void> deleteAccount() async {
    await ApiClient.delete('/v1/protected/');
  }
}
