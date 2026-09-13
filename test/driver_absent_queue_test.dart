import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/services/attendance_service.dart';

/// The rule that decides what the driver is shown during a morning pickup.
///
/// Mirrors `_buildPickup`'s `outstanding` predicate in dv_status_page.dart.
/// It is duplicated here rather than exported because the page's copy is three
/// lines inside a build method; what matters is that the behaviour it encodes
/// is pinned, because the previous version — filtering on WAITING alone — made
/// a parent's declaration completely invisible in the cab, and nothing failed
/// when it did.
bool outstanding(AttendanceStudent s, Set<int> acknowledged) =>
    s.status == AttendanceStatus.waiting ||
    (s.status == AttendanceStatus.absent &&
        !acknowledged.contains(s.attendanceId));

AttendanceStudent student(int id, String status) => AttendanceStudent(
  attendanceId: id,
  studentId: id,
  firstName: 'child$id',
  status: status,
);

void main() {
  group('the morning pickup queue', () {
    test('surfaces an absent child instead of skipping the stop', () {
      final roster = [
        student(1, AttendanceStatus.waiting),
        student(2, AttendanceStatus.absent),
        student(3, AttendanceStatus.waiting),
      ];

      final queue = roster.where((s) => outstanding(s, {})).toList();

      // The regression: the absent child must still be in the queue, and in
      // travel order, so the driver is told at the stop rather than finding
      // that a stop never came up.
      expect(queue.map((s) => s.attendanceId), [1, 2, 3]);
    });

    test('drops the absent child once acknowledged', () {
      final roster = [
        student(1, AttendanceStatus.absent),
        student(2, AttendanceStatus.waiting),
      ];

      final queue = roster.where((s) => outstanding(s, {1})).toList();

      expect(queue.map((s) => s.attendanceId), [2]);
    });

    test('boarded and arrived children never come back', () {
      final roster = [
        student(1, AttendanceStatus.boarded),
        student(2, AttendanceStatus.arrived),
        student(3, AttendanceStatus.waiting),
      ];

      expect(
        roster.where((s) => outstanding(s, {})).map((s) => s.attendanceId),
        [3],
      );
    });

    test('boarding an acknowledged absent child keeps them out', () {
      // The driver skipped them, then the child turned up and was boarded.
      final boarded = student(1, AttendanceStatus.boarded);
      expect(outstanding(boarded, {1}), isFalse);
      expect(outstanding(boarded, {}), isFalse);
    });

    test('the remaining count is pickups, not stops', () {
      final queue = [
        student(1, AttendanceStatus.absent),
        student(2, AttendanceStatus.waiting),
        student(3, AttendanceStatus.waiting),
      ];

      // An absent child is a stop to drive past, not someone to collect, so
      // they must not inflate "N pickups remaining".
      final remaining = queue
          .where((s) => s.status == AttendanceStatus.waiting)
          .length;
      expect(remaining, 2);
    });

    test('an all-absent roster still shows every stop before finishing', () {
      final roster = [
        student(1, AttendanceStatus.absent),
        student(2, AttendanceStatus.absent),
      ];

      expect(roster.where((s) => outstanding(s, {})), hasLength(2));
      expect(roster.where((s) => outstanding(s, {1})), hasLength(1));
      expect(roster.where((s) => outstanding(s, {1, 2})), isEmpty);
    });
  });
}
