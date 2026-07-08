import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/attendance_status_ui.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_broadcast_status.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_student_card.dart';
import 'package:mockup/services/api_client.dart';
import 'package:mockup/services/attendance_service.dart';
import 'package:mockup/services/protected_service.dart';

import '../../l10n/app_localizations.dart';

/// Which run the wall clock currently allows. The driver no longer picks:
/// 06:00–08:59 is the morning run, 13:00–15:59 the afternoon run, anything
/// else means no run can be started.
enum RunWindow { morning, afternoon, none }

RunWindow runWindowFor(DateTime now) {
  if (now.hour >= 6 && now.hour < 9) return RunWindow.morning;
  if (now.hour >= 13 && now.hour < 16) return RunWindow.afternoon;
  return RunWindow.none;
}

/// Driver home: drives the backend attendance flow.
///
/// Passive -> load /v1/protected/myroutes; the run phase comes from the
///            clock (see [runWindowFor]) and is shown read-only.
/// Morning -> a pickup page that surfaces one waiting student at a time;
///            boarding at pickup IS the attendance, so there is no
///            separate attendance page.
/// Afternoon -> attendance page first (tap/swipe board or absent), then a
///            drop-off page that surfaces one boarded student at a time.
/// Complete finalizes and shows a summary. The start endpoints are
/// idempotent, so re-entering an IN_PROGRESS run (e.g. after an app
/// restart) resumes with the current roster.
class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  List<DriverRoute>? _routes;
  DriverRoute? _selectedRoute;

  RunWindow _window = runWindowFor(DateTime.now());
  Timer? _clock;

  // Debug-build override so testers can force a phase outside its time
  // window. Null means the clock decides. Never set in release builds.
  RunWindow? _manualWindow;

  RunWindow get _effectiveWindow => _manualWindow ?? _window;

  // Frozen at start time so a run that crosses 9:00/16:00 keeps calling the
  // endpoints of the phase it was started in.
  bool _isAfternoon = false;

  RouteStart? _run;
  bool _droppingOff = false;
  final Set<int> _busyIds = {};
  bool _working = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      final window = runWindowFor(DateTime.now());
      if (window != _window && mounted) {
        setState(() => _window = window);
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _routes = null;
      _loadError = null;
    });
    try {
      final routes = await ProtectedService.getMyRoutes();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _selectedRoute = routes.isNotEmpty ? routes.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routes = const [];
        _loadError = e.toString();
      });
    }
  }

  Future<void> _startRun() async {
    final route = _selectedRoute;
    final window = _effectiveWindow;
    if (route == null || _working || window == RunWindow.none) return;
    setState(() => _working = true);
    try {
      final afternoon = window == RunWindow.afternoon;
      final run = afternoon
          ? await AttendanceService.startAfternoon(route.id)
          : await AttendanceService.startMorning(route.id);
      if (!mounted) return;
      setState(() {
        _isAfternoon = afternoon;
        _run = run;
        _droppingOff = false;
      });
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showConnectionError();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _transition(
    AttendanceStudent student,
    Future<AttendanceUpdate> Function(int attendanceId) call,
  ) async {
    if (_busyIds.contains(student.attendanceId)) return;
    setState(() => _busyIds.add(student.attendanceId));
    try {
      final result = await call(student.attendanceId);
      if (!mounted) return;
      setState(() => student.status = result.newStatus);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showConnectionError();
    } finally {
      if (mounted) setState(() => _busyIds.remove(student.attendanceId));
    }
  }

  Future<void> _completeRun() async {
    final l10n = AppLocalizations.of(context)!;
    final route = _selectedRoute;
    if (route == null || _working) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.completeRun),
        content: Text(l10n.completeRunDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      final summary = _isAfternoon
          ? await AttendanceService.completeAfternoon(route.id)
          : await AttendanceService.completeMorning(route.id);
      if (!mounted) return;
      setState(() {
        _run = null;
        _droppingOff = false;
      });
      _showSummary(summary);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showConnectionError();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showSummary(RunSummary summary) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.runCompleted),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow(l10n.summaryTotal, summary.totalStudents),
            _summaryRow(
              _isAfternoon ? l10n.summaryDroppedOff : l10n.summaryArrived,
              summary.delivered,
            ),
            _summaryRow(l10n.summaryAbsent, summary.absent),
            if (summary.tripDuration != null)
              _summaryTextRow(
                l10n.summaryDuration,
                _formatDuration(summary.tripDuration!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int value) =>
      _summaryTextRow(label, '$value');

  Widget _summaryTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // H:MM:SS when the trip ran an hour or more, otherwise MM:SS.
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.dangerRed),
    );
  }

  void _showConnectionError() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _showError(l10n.connectionError);
  }

  @override
  Widget build(BuildContext context) {
    final routes = _routes;
    if (routes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final Widget child;
    if (_run == null) {
      child = _buildPassive(routes);
    } else if (!_isAfternoon) {
      child = _buildPickup();
    } else if (_droppingOff) {
      child = _buildDropoff();
    } else {
      child = _buildAttendance();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  Widget _buildPassive(List<DriverRoute> routes) {
    final l10n = AppLocalizations.of(context)!;

    if (routes.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Text(_loadError ?? l10n.noRoutesAssigned),
            OutlinedButton(
              onPressed: _loadRoutes,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final window = _effectiveWindow;
    return ListView(
      key: const ValueKey('passive'),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF1A2B48),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus_filled_outlined,
                      color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text(
                      l10n.myRoute,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              if (routes.length == 1)
                Text(
                  routes.first.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                DropdownButton<DriverRoute>(
                  value: _selectedRoute,
                  dropdownColor: const Color(0xFF1A2B48),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  items: [
                    for (final r in routes)
                      DropdownMenuItem(value: r, child: Text(r.name)),
                  ],
                  onChanged: (r) => setState(() => _selectedRoute = r),
                ),
              _buildRunWindowBanner(l10n, window),
              if (kDebugMode)
                SegmentedButton<RunWindow>(
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: RunWindow.morning,
                      label: Text(l10n.morningRun),
                      icon: const Icon(Icons.wb_sunny_outlined),
                    ),
                    ButtonSegment(
                      value: RunWindow.afternoon,
                      label: Text(l10n.afternoonRun),
                      icon: const Icon(Icons.home_outlined),
                    ),
                  ],
                  selected: _manualWindow != null
                      ? {_manualWindow!}
                      : window != RunWindow.none
                          ? {window}
                          : const <RunWindow>{},
                  onSelectionChanged: (s) => setState(
                      () => _manualWindow = s.isEmpty ? null : s.first),
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                ),
              ElevatedButton.icon(
                onPressed:
                    _working || window == RunWindow.none ? null : _startRun,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _working
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_outlined),
                label: Text(l10n.startSession.toUpperCase()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Read-only replacement for the old morning/afternoon segmented picker:
  /// shows which run the clock has selected, or the schedule when neither
  /// window is open.
  Widget _buildRunWindowBanner(AppLocalizations l10n, RunWindow window) {
    if (window == RunWindow.none) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(Icons.schedule, color: Colors.grey, size: 20),
                Text(
                  l10n.noRunScheduled,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              l10n.runWindowsInfo,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final afternoon = window == RunWindow.afternoon;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 8,
        children: [
          Icon(
            afternoon ? Icons.home_outlined : Icons.wb_sunny_outlined,
            size: 22,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currentRunLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                afternoon ? l10n.afternoonRun : l10n.morningRun,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// First afternoon page: the driver marks every student as on the bus or
  /// absent (tap / swipe / toggles), then continues to the drop-off page.
  /// Morning runs never come here — pickup is their attendance.
  Widget _buildAttendance() {
    final l10n = AppLocalizations.of(context)!;
    final run = _run!;

    return ListView(
      key: const ValueKey('attendance'),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25, top: 15),
          child: Text(
            '${l10n.afternoonRun} — ${l10n.attendanceTitle}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 25, bottom: 5, right: 25),
          child: Text(
            l10n.attendanceHint,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        for (final student in run.students)
          DvStudentCard(
            student: student,
            busy: _busyIds.contains(student.attendanceId),
            onBoard: () =>
                _transition(student, AttendanceService.boardAfternoon),
            onAbsent: () =>
                _transition(student, AttendanceService.absentAfternoon),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _droppingOff = true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.startDropoffs.toUpperCase()),
          ),
        ),
        const DvBroadcastStatus(),
      ],
    );
  }

  /// Morning active page: one waiting student at a time, dropoff-page card
  /// style. Boarding at pickup counts as attendance; already-handled
  /// students stay listed below with a toggle so mistakes are correctable.
  Widget _buildPickup() {
    final l10n = AppLocalizations.of(context)!;
    final run = _run!;
    final waiting = run.students
        .where((s) => s.status == AttendanceStatus.waiting)
        .toList();
    final handled = run.students
        .where((s) => s.status != AttendanceStatus.waiting)
        .toList();

    return ListView(
      key: const ValueKey('pickup'),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25, top: 15),
          child: Text(
            '${l10n.morningRun} — ${l10n.nextPickup}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 25, bottom: 5),
          child: Text(
            l10n.pickupRemaining(waiting.length),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        if (waiting.isEmpty)
          _buildAllDoneCard(l10n.allPickedUp)
        else ...[
          _buildNextStudentCard(
            waiting.first,
            actionLabel: l10n.board,
            actionIcon: Icons.directions_bus_filled,
            onAction: () =>
                _transition(waiting.first, AttendanceService.boardMorning),
            secondaryLabel: l10n.absent,
            onSecondary: () =>
                _transition(waiting.first, AttendanceService.absentMorning),
          ),
          if (waiting.length > 1) ...[
            _sectionHeader(l10n.upNext),
            for (final student in waiting.skip(1)) _upNextRow(student),
          ],
        ],
        if (handled.isNotEmpty) ...[
          _sectionHeader(l10n.studentsTitle),
          for (final student in handled) _handledRow(student),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _completeRunButton(l10n),
        ),
        const DvBroadcastStatus(),
      ],
    );
  }

  /// Compact row for a boarded/absent student on the pickup page with a
  /// single toggle to flip the status if it was a mistake.
  Widget _handledRow(AttendanceStudent student) {
    final busy = _busyIds.contains(student.attendanceId);
    final absent = student.status == AttendanceStatus.absent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsetsDirectional.only(start: 15, end: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F3),
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(absent ? Icons.person_off_outlined : Icons.child_care,
              size: 22, color: absent ? AppColors.dangerRed : null),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: Text(student.firstName,
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: attendanceStatusColor(student.status),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              attendanceStatusLabel(context, student.status).toUpperCase(),
              style: const TextStyle(fontSize: 11),
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                absent
                    ? Icons.directions_bus_filled
                    : Icons.person_off_outlined,
                size: 20,
                color: absent ? Colors.green : AppColors.dangerRed,
              ),
              onPressed: () => _transition(
                student,
                absent
                    ? AttendanceService.boardMorning
                    : AttendanceService.absentMorning,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _upNextRow(AttendanceStudent student) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F3),
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        spacing: 12,
        children: [
          const Icon(Icons.child_care, size: 22),
          Text(student.firstName, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAllDoneCard(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F3),
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        spacing: 10,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 48, color: Colors.green),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Second active page (afternoon only): one boarded student at a time,
  /// name front and center with a prominent drop-off button. Absent and
  /// not-boarded students never appear here.
  Widget _buildDropoff() {
    final l10n = AppLocalizations.of(context)!;
    final run = _run!;
    final boarded = run.students
        .where((s) => s.status == AttendanceStatus.boarded)
        .toList();

    return ListView(
      key: const ValueKey('dropoff'),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25, top: 15),
          child: Text(
            '${l10n.afternoonRun} — ${l10n.nextDropoff}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 25, bottom: 5),
          child: Text(
            l10n.dropoffRemaining(boarded.length),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        if (boarded.isEmpty)
          _buildAllDoneCard(l10n.allDroppedOff)
        else ...[
          _buildNextStudentCard(
            boarded.first,
            actionLabel: l10n.dropoff,
            actionIcon: Icons.done,
            onAction: () => _transition(
                boarded.first, AttendanceService.dropoffAfternoon),
          ),
          if (boarded.length > 1) ...[
            _sectionHeader(l10n.upNext),
            for (final student in boarded.skip(1)) _upNextRow(student),
          ],
        ],
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
          child: TextButton.icon(
            onPressed: () => setState(() => _droppingOff = false),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(l10n.backToAttendance),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _completeRunButton(l10n),
        ),
        const DvBroadcastStatus(),
      ],
    );
  }

  /// Prominent "current student" card shared by the morning pickup and
  /// afternoon drop-off pages: big name, one primary action, and an
  /// optional secondary action (mark absent during pickup).
  Widget _buildNextStudentCard(
    AttendanceStudent student, {
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    final busy = _busyIds.contains(student.attendanceId);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B48),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        spacing: 20,
        children: [
          const Icon(Icons.child_care, size: 48, color: Colors.white),
          Text(
            student.firstName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: busy ? null : onAction,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A2B48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            icon: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(actionIcon, size: 26),
            label: Text(actionLabel.toUpperCase()),
          ),
          if (secondaryLabel != null && onSecondary != null)
            TextButton.icon(
              onPressed: busy ? null : onSecondary,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade200,
              ),
              icon: const Icon(Icons.person_off_outlined, size: 20),
              label: Text(secondaryLabel),
            ),
        ],
      ),
    );
  }

  Widget _completeRunButton(AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: _working ? null : _completeRun,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: AppColors.dangerRed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
      label: Text(
        l10n.completeRun.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
