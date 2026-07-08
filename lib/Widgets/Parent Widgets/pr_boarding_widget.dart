import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/attendance_status_ui.dart';
import 'package:mockup/services/protected_service.dart';
import 'package:mockup/services/socket_service.dart';

import '../../l10n/app_localizations.dart';

/// Live boarding status for the parent's own children.
///
/// Names come from GET /v1/protected/students. Live statuses arrive over
/// socket.io: the widget joins each child's `route:<id>` room and applies
/// attendance events. The backend has no REST endpoint for parents to
/// read attendance, so until the driver starts a run (which broadcasts
/// the roster) statuses show as "waiting for the driver".
class PrBoardingWidget extends StatefulWidget {
  const PrBoardingWidget({super.key});

  @override
  State<PrBoardingWidget> createState() => _PrBoardingWidgetState();
}

class _PrBoardingWidgetState extends State<PrBoardingWidget> {
  List<Student>? _students;
  String? _error;

  /// studentId -> live attendance status (filled by socket events).
  final Map<int, String> _statusByStudent = {};

  /// attendanceId -> studentId, learned from roster broadcasts so that
  /// later per-student `attendance:updated` events can be applied.
  final Map<int, int> _studentByAttendance = {};

  final Set<int> _joinedRoutes = {};
  StreamSubscription<AttendanceEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final id in _joinedRoutes) {
      SocketService.instance.leaveRoute(id);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _students = null;
      _error = null;
    });
    try {
      final students = await ProtectedService.getStudents();
      if (!mounted) return;
      setState(() => _students = students);

      _sub ??= SocketService.instance.events.listen(_onEvent);
      for (final s in students) {
        final routeId = s.routeId;
        if (routeId != null && _joinedRoutes.add(routeId)) {
          SocketService.instance.joinRoute(routeId);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _students = const [];
        _error = e.toString();
      });
    }
  }

  void _onEvent(AttendanceEvent event) {
    final students = _students;
    if (students == null || !mounted) return;

    setState(() {
      switch (event.type) {
        case AttendanceEventType.morningStarted:
        case AttendanceEventType.afternoonStarted:
        case AttendanceEventType.morningCompleted:
        case AttendanceEventType.afternoonCompleted:
          final mine = students.map((s) => s.id).toSet();
          for (final rosterStudent in event.students) {
            if (mine.contains(rosterStudent.studentId)) {
              _studentByAttendance[rosterStudent.attendanceId] =
                  rosterStudent.studentId;
              _statusByStudent[rosterStudent.studentId] =
                  rosterStudent.status;
            }
          }
        case AttendanceEventType.studentUpdated:
          final studentId = _studentByAttendance[event.attendanceId];
          final status = event.newStatus;
          if (studentId != null && status != null) {
            _statusByStudent[studentId] = status;
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final students = _students;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderGray),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    left: 5.0,
                    right: 5.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.boardingStatus,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.group),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: switch (students) {
                  null => const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    ),
                  [] => Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        spacing: 8,
                        children: [
                          Text(_error ?? l10n.noStudentsLinked),
                          if (_error != null)
                            OutlinedButton(
                              onPressed: _load,
                              child: Text(l10n.retry),
                            ),
                        ],
                      ),
                    ),
                  _ => Column(
                      spacing: 10.0,
                      children: [
                        for (final student in students)
                          _studentRow(context, student),
                      ],
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentRow(BuildContext context, Student student) {
    final l10n = AppLocalizations.of(context)!;
    final status = _statusByStudent[student.id];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F3),
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 14.0),
              child: Icon(Icons.child_care, size: 26),
            ),
            Expanded(
              child: Text(
                student.firstName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: status == null
                    ? const Color(0xFFE9E7EC)
                    : attendanceStatusColor(status),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0,
                ),
                child: Text(
                  status == null
                      ? l10n.waitingForDriver
                      : attendanceStatusLabel(context, status)
                          .toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
