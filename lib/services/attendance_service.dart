import 'package:mockup/Util/calendar_date.dart';

import 'api_client.dart';

/// Mirrors backend utils/enum.js ATTENDANCE_STATUS.
class AttendanceStatus {
  static const String waiting = 'WAITING';
  static const String boarded = 'BOARDED';
  static const String arrived = 'ARRIVED';
  static const String absent = 'ABSENT';
  static const String droppedOff = 'DROPPED_OFF';
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
      status:
          (json['status'] ??
                  json['afternoon_status'] ??
                  json['morning_status'] ??
                  AttendanceStatus.waiting)
              as String,
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
      delivered: (summary['arrived'] ?? summary['dropped_off'] ?? 0) as int,
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

/// One student's recorded attendance for a single past day.
///
/// Both status fields are nullable: a phase that never ran that day leaves
/// its column NULL in the backend's attendance table.
class AttendanceRecord {
  final int attendanceId;
  final int studentId;
  final String firstName;
  final String parentName;
  final String? morningStatus;
  final String? afternoonStatus;

  const AttendanceRecord({
    required this.attendanceId,
    required this.studentId,
    required this.firstName,
    required this.parentName,
    this.morningStatus,
    this.afternoonStatus,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      attendanceId: json['attendanceid'] as int,
      studentId: json['id'] as int,
      firstName: (json['first_name'] ?? '') as String,
      parentName: (json['parent_name'] ?? '') as String,
      morningStatus: json['morning_status'] as String?,
      afternoonStatus: json['afternoon_status'] as String?,
    );
  }

  String? statusFor({required bool afternoon}) =>
      afternoon ? afternoonStatus : morningStatus;
}

/// A completed run day: every student's record for one calendar date.
///
/// Counts are derived on the client — the backend returns raw rows only.
/// "Present" is any recorded status other than ABSENT.
class TripSession {
  /// The date as the backend expects it (YYYY-MM-DD).
  final String date;

  /// The same day as a local calendar date, for display/formatting.
  final DateTime day;

  final List<AttendanceRecord> records;

  const TripSession({
    required this.date,
    required this.day,
    required this.records,
  });

  int get total => records.length;

  int recorded({required bool afternoon}) =>
      records.where((r) => r.statusFor(afternoon: afternoon) != null).length;

  int present({required bool afternoon}) => records.where((r) {
    final s = r.statusFor(afternoon: afternoon);
    return s != null && s != AttendanceStatus.absent;
  }).length;

  int absent({required bool afternoon}) => records
      .where(
        (r) => r.statusFor(afternoon: afternoon) == AttendanceStatus.absent,
      )
      .length;

  bool get hasMorning => recorded(afternoon: false) > 0;
  bool get hasAfternoon => recorded(afternoon: true) > 0;
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
        await ApiClient.post('/v1/attendance/$routeId/morning/start'),
      );

  static Future<AttendanceUpdate> boardMorning(int attendanceId) async =>
      AttendanceUpdate.fromJson(
        await ApiClient.post('/v1/attendance/$attendanceId/morning/board'),
      );

  static Future<AttendanceUpdate> absentMorning(int attendanceId) async =>
      AttendanceUpdate.fromJson(
        await ApiClient.post('/v1/attendance/$attendanceId/morning/absent'),
      );

  static Future<RunSummary> completeMorning(int routeId) async =>
      RunSummary.fromJson(
        await ApiClient.post('/v1/attendance/$routeId/morning/complete'),
      );

  static Future<RouteStart> startAfternoon(int routeId) async =>
      RouteStart.fromJson(
        await ApiClient.post('/v1/attendance/$routeId/afternoon/start'),
      );

  static Future<AttendanceUpdate> boardAfternoon(int attendanceId) async =>
      AttendanceUpdate.fromJson(
        await ApiClient.post('/v1/attendance/$attendanceId/afternoon/board'),
      );

  static Future<AttendanceUpdate> absentAfternoon(int attendanceId) async =>
      AttendanceUpdate.fromJson(
        await ApiClient.post('/v1/attendance/$attendanceId/afternoon/absent'),
      );

  static Future<AttendanceUpdate> dropoffAfternoon(int attendanceId) async =>
      AttendanceUpdate.fromJson(
        await ApiClient.patch('/v1/attendance/$attendanceId/afternoon/dropoff'),
      );

  static Future<RunSummary> completeAfternoon(int routeId) async =>
      RunSummary.fromJson(
        await ApiClient.post('/v1/attendance/$routeId/afternoon/complete'),
      );

  // ---------------------------------------------------------------- history

  /// Every student's recorded attendance on one date.
  /// A date with no run comes back as an empty list (the backend answers 200
  /// with `students: []` rather than 404).
  static Future<List<AttendanceRecord>> attendanceOn(
    int routeId,
    DateTime day,
  ) async {
    final body = await ApiClient.post(
      '/v1/attendance/$routeId/attendance',
      body: {'date': formatCalendarDate(day)},
    );
    return (body['students'] as List? ?? [])
        .map(
          (e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// Loads the run days in a window ending at [endDay] and going back
  /// [days] days, newest first. Days with no run are omitted.
  ///
  /// The backend has no "list past sessions" endpoint, so this probes one
  /// request per day. Requests go out in small concurrent batches to keep a
  /// mobile connection from being flooded. If every probe fails (e.g. the
  /// server is unreachable) the first error is rethrown rather than
  /// reporting an empty history.
  ///
  /// `unreadableDays` counts the probes that failed while others succeeded.
  /// A day that could not be read is indistinguishable from a day with no run
  /// once it is dropped, so returning the count is what lets the caller say
  /// "this list is incomplete" instead of quietly showing a history with
  /// holes in it.
  static Future<({List<TripSession> sessions, int unreadableDays})>
  loadSessions(
    int routeId, {
    required DateTime endDay,
    required int days,
    int concurrency = 5,
  }) async {
    final wanted = [
      for (var i = 0; i < days; i++)
        DateTime(endDay.year, endDay.month, endDay.day - i),
    ];

    final sessions = <TripSession>[];
    Object? firstError;
    var unreadable = 0;

    for (var i = 0; i < wanted.length; i += concurrency) {
      final batch = wanted.skip(i).take(concurrency);
      final results = await Future.wait(
        batch.map((day) async {
          try {
            final records = await attendanceOn(routeId, day);
            if (records.isEmpty) return null;
            return TripSession(
              date: formatCalendarDate(day),
              day: day,
              records: records,
            );
          } catch (e) {
            firstError ??= e;
            unreadable++;
            return null;
          }
        }),
      );
      sessions.addAll(results.whereType<TripSession>());
    }

    if (sessions.isEmpty && firstError != null) throw firstError!;

    sessions.sort((a, b) => b.day.compareTo(a.day));
    return (sessions: sessions, unreadableDays: unreadable);
  }
}
