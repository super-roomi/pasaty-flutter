import 'api_client.dart';

/// Mirrors backend utils/enum.js ATTENDANCE_STATUS.
class AttendanceStatus {
  static const String waiting = 'WAITING';
  static const String boarded = 'BOARDED';
  static const String arrived = 'ARRIVED';
  static const String absent = 'ABSENT';
  static const String droppedOff = 'DROPPED_OFF';
}

/// Mirrors backend utils/enum.js ROUTE_STATUS.
class RouteStatus {
  static const String inProgress = 'IN_PROGRESS';
  static const String cancelled = 'CANCELLED';
  static const String completed = 'COMPLETED';
}

/// Student row returned by start/complete endpoints.
/// Morning payloads carry a single `status`; afternoon payloads carry
/// `morning_status` + `afternoon_status` instead.
class AttendanceStudent {
  final int attendanceId;
  final int studentId;
  final String firstName;
  String status;

  AttendanceStudent({
    required this.attendanceId,
    required this.studentId,
    required this.firstName,
    required this.status,
  });

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) {
    return AttendanceStudent(
      attendanceId: json['attendanceid'] as int,
      studentId: json['id'] as int,
      firstName: (json['first_name'] ?? '') as String,
      status: (json['status'] ??
          json['afternoon_status'] ??
          json['morning_status'] ??
          AttendanceStatus.waiting) as String,
    );
  }
}

/// Result of board/absent/dropoff calls.
class AttendanceUpdate {
  final bool changed;
  final int attendanceId;
  final int routeId;
  final String oldStatus;
  final String newStatus;

  const AttendanceUpdate({
    required this.changed,
    required this.attendanceId,
    required this.routeId,
    required this.oldStatus,
    required this.newStatus,
  });

  factory AttendanceUpdate.fromJson(Map<String, dynamic> json) {
    return AttendanceUpdate(
      changed: json['changed'] as bool,
      attendanceId: json['attendanceid'] as int,
      routeId: json['routeid'] as int,
      oldStatus: (json['old_status'] ?? '') as String,
      newStatus: (json['new_status'] ?? '') as String,
    );
  }
}

/// Result of the complete endpoints: final list + counts.
class RunSummary {
  final int totalStudents;
  final int delivered; // arrived (morning) / dropped_off (afternoon)
  final int absent;
  final Duration? tripDuration;
  final List<AttendanceStudent> students;

  const RunSummary({
    required this.totalStudents,
    required this.delivered,
    required this.absent,
    required this.tripDuration,
    required this.students,
  });

  factory RunSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return RunSummary(
      totalStudents: summary['total_students'] as int,
      delivered:
          (summary['arrived'] ?? summary['dropped_off'] ?? 0) as int,
      absent: (summary['absent'] ?? 0) as int,
      tripDuration: _parseInterval(summary['trip_duration']),
      students: (json['students'] as List)
          .map((e) => AttendanceStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // Backend sends a Postgres interval, serialized as an object with only the
  // non-zero fields present (e.g. {"minutes":45,"seconds":12}).
  static Duration? _parseInterval(dynamic raw) {
    if (raw is! Map) return null;
    int f(String k) => (raw[k] as num?)?.toInt() ?? 0;
    return Duration(
      days: f('days'),
      hours: f('hours'),
      minutes: f('minutes'),
      seconds: f('seconds'),
      milliseconds: f('milliseconds'),
    );
  }
}

/// Route + pickup list returned by the start endpoints.
class RouteStart {
  final int routeId;
  final List<AttendanceStudent> students;

  const RouteStart({required this.routeId, required this.students});

  factory RouteStart.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>;
    return RouteStart(
      routeId: route['id'] as int,
      students: (json['students'] as List)
          .map((e) => AttendanceStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Driver-only client for /v1/attendance/*.
///
/// Backend contract (AttendanceRouter.js): start/complete take :routeid,
/// board/absent/dropoff take :attendanceid. All idempotent — re-tapping
/// returns changed:false instead of erroring. Failures use HTTP status:
/// 403 not your route, 409 wrong phase state, 404 unknown id.
class AttendanceService {
  static Future<RouteStart> startMorning(int routeId) async =>
      RouteStart.fromJson(
          await ApiClient.post('/v1/attendance/$routeId/morning/start'));

  static Future<AttendanceUpdate> boardMorning(int attendanceId) async =>
      AttendanceUpdate.fromJson(
          await ApiClient.post('/v1/attendance/$attendanceId/morning/board'));

  static Future<AttendanceUpdate> absentMorning(int attendanceId) async =>
      AttendanceUpdate.fromJson(
          await ApiClient.post('/v1/attendance/$attendanceId/morning/absent'));

  static Future<RunSummary> completeMorning(int routeId) async =>
      RunSummary.fromJson(
          await ApiClient.post('/v1/attendance/$routeId/morning/complete'));

  static Future<RouteStart> startAfternoon(int routeId) async =>
      RouteStart.fromJson(
          await ApiClient.post('/v1/attendance/$routeId/afternoon/start'));

  static Future<AttendanceUpdate> boardAfternoon(int attendanceId) async =>
      AttendanceUpdate.fromJson(await ApiClient.post(
          '/v1/attendance/$attendanceId/afternoon/board'));

  static Future<AttendanceUpdate> absentAfternoon(int attendanceId) async =>
      AttendanceUpdate.fromJson(await ApiClient.post(
          '/v1/attendance/$attendanceId/afternoon/absent'));

  static Future<AttendanceUpdate> dropoffAfternoon(int attendanceId) async =>
      AttendanceUpdate.fromJson(await ApiClient.patch(
          '/v1/attendance/$attendanceId/afternoon/dropoff'));

  static Future<RunSummary> completeAfternoon(int routeId) async =>
      RunSummary.fromJson(
          await ApiClient.post('/v1/attendance/$routeId/afternoon/complete'));
}
