import 'package:mockup/Util/calendar_date.dart';

import 'api_client.dart';

/// What the server did with one requested day.
///
/// A declare request answers per day rather than as a whole, because a range
/// can be partly honoured — today is too late but the rest of the week is
/// fine. Only when *no* day could be booked does the call fail outright.
enum AbsenceDayState {
  /// Booked. That morning's register will read it.
  planned,

  /// Already booked; nothing changed. Success, not an error — re-tapping is
  /// safe and must not look like a failure.
  existing,

  /// The run was already out, so the child was taken off it there and then.
  /// The driver's screen updates without a refresh.
  live,

  /// Nothing changed. See [AbsenceDay.reason].
  tooLate,
}

/// Why a day was refused. Structured, unlike the prose in a 409 body, so the
/// wording shown to the parent can come from the ARB files.
class AbsenceRefusal {
  /// The child is already on the bus.
  static const alreadyBoarded = 'already_boarded';

  /// This morning's run has finished.
  static const runFinished = 'run_finished';
}

/// One day of a declare response.
class AbsenceDay {
  /// `YYYY-MM-DD` in the school's timezone, exactly as the server wrote it.
  ///
  /// Deliberately a string. Parsing it to a [DateTime] would re-interpret a
  /// school-timezone calendar label in the device's zone, which is how a
  /// phone one timezone away ends up displaying — and then cancelling — the
  /// wrong day.
  final String date;

  final AbsenceDayState state;
  final String? reason;

  const AbsenceDay({required this.date, required this.state, this.reason});

  /// True when this day ended up booked, however it got there.
  bool get booked => state != AbsenceDayState.tooLate;

  factory AbsenceDay.fromJson(Map<String, dynamic> json) {
    return AbsenceDay(
      date: (json['date'] ?? '').toString(),
      state: switch (json['state']) {
        'planned' => AbsenceDayState.planned,
        'existing' => AbsenceDayState.existing,
        'live' => AbsenceDayState.live,
        _ => AbsenceDayState.tooLate,
      },
      reason: json['reason'] as String?,
    );
  }
}

/// The result of declaring one or more days.
class AbsenceResult {
  final int studentId;
  final List<AbsenceDay> days;

  const AbsenceResult({required this.studentId, required this.days});

  List<AbsenceDay> get booked => days.where((d) => d.booked).toList();
  List<AbsenceDay> get refused =>
      days.where((d) => d.state == AbsenceDayState.tooLate).toList();

  /// True when the run was out and the child came off it immediately, which
  /// is worth telling the parent about explicitly — the driver has been told.
  bool get anyLive => days.any((d) => d.state == AbsenceDayState.live);

  factory AbsenceResult.fromJson(Map<String, dynamic> json) {
    return AbsenceResult(
      studentId: (json['studentid'] as num).toInt(),
      days: (json['days'] as List? ?? const [])
          .map((e) => AbsenceDay.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// One booked day already on file.
class PlannedAbsence {
  final int id;
  final int studentId;

  /// `YYYY-MM-DD` in the school's timezone. String for the same reason as
  /// [AbsenceDay.date].
  final String date;

  final String studentName;

  const PlannedAbsence({
    required this.id,
    required this.studentId,
    required this.date,
    required this.studentName,
  });

  factory PlannedAbsence.fromJson(Map<String, dynamic> json) {
    return PlannedAbsence(
      id: (json['id'] as num).toInt(),
      studentId: (json['studentid'] as num).toInt(),
      date: (json['date'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
    );
  }
}

/// The booked days, plus the school's own calendar day.
///
/// [today] is the server's answer, not the device's. It is what every day
/// offered in the UI is counted from, so a phone in the wrong timezone cannot
/// label — or book — the wrong morning.
class AbsenceWindow {
  final String today;
  final List<PlannedAbsence> absences;

  const AbsenceWindow({required this.today, required this.absences});

  /// Calendar arithmetic on a plain label. Safe in a way that deriving
  /// *today* on-device is not: nothing here converts to or from an instant,
  /// so no timezone can shift the result.
  static String addDays(String date, int days) {
    final parts = date.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return date;
    final shifted = DateTime.utc(
      parts[0]!,
      parts[1]!,
      parts[2]!,
    ).add(Duration(days: days));
    return formatCalendarDate(shifted);
  }
}

/// Parent-only client for /v1/protected/absence.
///
/// Takes a child off a morning run — now, or days ahead. A declaration is
/// advisory: if the child turns up anyway the driver can still board them, so
/// nothing here is destructive.
///
/// Afternoon is deliberately out of scope. A morning absence carries forward
/// on its own, and there is no afternoon endpoint to call.
class AbsenceService {
  /// The server caps a single request at 30 days, and the default listing
  /// window is the same length.
  static const int maxRangeDays = 30;

  /// Declares the child absent for **today**, sending no date at all.
  ///
  /// The omission is the point. "Today" is a school-timezone calendar day and
  /// only the server knows which one that is; a phone in the wrong timezone
  /// that computes it locally books the neighbouring day, and the failure is
  /// silent — a child skipped on a morning they should have ridden.
  static Future<AbsenceResult> declareToday(int studentId) async =>
      AbsenceResult.fromJson(
        await ApiClient.post(
          '/v1/protected/absence',
          body: {'studentid': studentId},
        ),
      );

  /// Declares the child absent across a chosen span, inclusive.
  ///
  /// Dates are sent here because the parent is naming days off a calendar
  /// rather than asking for "now". [to] defaults to [from] server-side; it is
  /// sent explicitly so a single-day booking reads the same as a range.
  static Future<AbsenceResult> declareRange({
    required int studentId,
    required DateTime from,
    required DateTime to,
  }) => declareDays(
    studentId: studentId,
    from: formatCalendarDate(from),
    to: formatCalendarDate(to),
  );

  /// Declares a span given as calendar labels.
  ///
  /// Preferred over [declareRange] when the days were counted from the
  /// server's own today, because it never round-trips through a [DateTime].
  static Future<AbsenceResult> declareDays({
    required int studentId,
    required String from,
    required String to,
  }) async => AbsenceResult.fromJson(
    await ApiClient.post(
      '/v1/protected/absence',
      body: {'studentid': studentId, 'from': from, 'to': to},
    ),
  );

  /// Cancels one booked day, putting the child back on that morning's run.
  ///
  /// Fails with 409 once that morning's run has started: the booking has
  /// already become a real ABSENT, and putting a child back onto a bus that
  /// has left is the driver's call, not ours.
  ///
  /// There is no range delete — cancelling a span is a loop over its days.
  static Future<void> cancel({
    required int studentId,
    required String date,
  }) async {
    await ApiClient.delete(
      '/v1/protected/absence',
      body: {'studentid': studentId, 'date': date},
    );
  }

  /// Every upcoming booked day for all of this parent's children.
  ///
  /// Both bounds are optional; the server defaults to today through today
  /// plus 30 days, which is the window the UI shows.
  static Future<AbsenceWindow> upcoming({DateTime? from, DateTime? to}) async {
    final query = <String>[
      if (from != null) 'from=${formatCalendarDate(from)}',
      if (to != null) 'to=${formatCalendarDate(to)}',
    ];
    final path =
        '/v1/protected/absence${query.isEmpty ? '' : '?${query.join('&')}'}';

    final body = await ApiClient.get(path);
    return AbsenceWindow(
      // With no bounds the server answers from its own today, which is the
      // only trustworthy source for which calendar day it is at the school.
      today: (body['from'] ?? '').toString(),
      absences: (body['absences'] as List? ?? const [])
          .map(
            (e) => PlannedAbsence.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
