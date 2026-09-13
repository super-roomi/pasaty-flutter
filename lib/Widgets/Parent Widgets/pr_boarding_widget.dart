import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/child_location_ui.dart';
import 'package:mockup/Util/error_text.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_section_header.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_state_view.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_absence_sheet.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_status_passive_widget.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_trip_progress_widget.dart';
import 'package:mockup/services/absence_service.dart';
import 'package:mockup/services/attendance_service.dart';
import 'package:mockup/services/protected_service.dart';
import 'package:mockup/services/socket_service.dart';

import '../../l10n/app_localizations.dart';

/// Where the parent's children are right now.
///
/// Two sources, in this order:
///  1. GET /v1/protected/attendance/:id per child on load, so opening the app
///     mid-route shows the truth immediately rather than waiting for the next
///     broadcast. A child with no record today is at home.
///  2. socket.io events on `route:<id>`, which update the same maps live.
///
/// The roster is always rendered. When no run has started today the passive
/// banner sits above it and every child reads "At home".
class PrBoardingWidget extends StatefulWidget {
  const PrBoardingWidget({super.key, this.trailing});

  /// Rendered below the roster inside the same scroll view, so the page has
  /// a single scrollable and pull-to-refresh covers the whole screen.
  final Widget? trailing;

  @override
  State<PrBoardingWidget> createState() => _PrBoardingWidgetState();
}

class _PrBoardingWidgetState extends State<PrBoardingWidget>
    with WidgetsBindingObserver {
  List<Student>? _students;
  String? _error;

  /// studentId -> latest attendance status.
  final Map<int, String> _statusByStudent = {};

  /// studentId -> phase that status belongs to. The same status means a
  /// different place in the morning than in the afternoon.
  final Map<int, String> _phaseByStudent = {};

  /// attendanceId -> studentId, learned from roster broadcasts so that
  /// later per-student `attendance:updated` events can be applied.
  final Map<int, int> _studentByAttendance = {};

  /// studentId -> the upcoming mornings that child is booked off, ascending.
  ///
  /// Loaded alongside the roster so a parent can see a booking on the row
  /// without opening anything. Dates stay as the server's `YYYY-MM-DD`
  /// labels; see [AbsenceDay.date] for why they are never parsed here.
  Map<int, List<PlannedAbsence>> _absencesByStudent = const {};

  final Set<int> _joinedRoutes = {};
  StreamSubscription<AttendanceEvent>? _sub;

  /// Latest estimate per route, or empty before the first ping.
  ///
  /// Keyed by route because a parent can have children riding different
  /// buses. Holding a single estimate meant the two routes' broadcasts
  /// overwrote each other several times a minute, and the card flickered
  /// between them.
  final Map<int, RouteEta> _etaByRoute = {};

  StreamSubscription<RouteEta>? _etaSub;

  /// Redraws the countdown between server pings, and retires an estimate the
  /// moment it goes stale.
  Timer? _etaTicker;

  /// How long an estimate is trusted to still be falling.
  ///
  /// The server speaks only on a driver position ping, roughly every 15
  /// seconds, so 90s of silence means several were missed — the phone lost
  /// signal, or the run ended. Past this the last figure is still shown but
  /// labelled as not updating, rather than counting down towards an arrival
  /// that may never come.
  static const Duration _etaMaxAge = Duration(seconds: 90);

  /// The single estimate shown for the whole card: the next arrival.
  ///
  /// Siblings ride the same bus to the same school, so the one figure that
  /// matters is the earliest upcoming stop. Its remaining route distance rides
  /// along so the parent sees how far the bus is, not only when.
  ///
  /// Returns null when no child on this card has an outstanding stop —
  /// everyone boarded, dropped off, or absent.
  TripEta? get _tripEta {
    final students = _students;
    if (students == null || _etaByRoute.isEmpty) return null;

    StopEta? next;
    RouteEta? nextRoute;
    var approximate = false;
    var stale = false;

    for (final student in students) {
      final routeEta = _etaByRoute[student.routeId];
      final stop = routeEta?.byStudent[student.id];
      if (routeEta == null || stop == null) continue;

      if (next == null || stop.eta.isBefore(next.eta)) {
        next = stop;
        nextRoute = routeEta;
      }
      approximate = approximate || routeEta.lowConfidence;

      if (DateTime.now().difference(routeEta.generatedAt) > _etaMaxAge) {
        stale = true;
      }
    }

    if (next == null || nextRoute == null) return null;

    // Measured against the broadcast rather than the clock, so a stale figure
    // reports what was last actually known.
    final staleMinutes =
        (next.eta.difference(nextRoute.generatedAt).inSeconds / 60)
            .ceil()
            .clamp(0, 999);

    return TripEta(
      arrival: next.eta,
      metersAway: next.metersAway,
      approximate: approximate,
      stale: stale,
      staleMinutes: staleMinutes,
    );
  }

  /// Whether a run is actually under way right now.
  ///
  /// Derived from the statuses rather than from run events, so it is correct
  /// on both paths (a live broadcast and a cold REST load). WAITING and
  /// BOARDED are the only non-terminal states in either phase: once every
  /// child has landed on ARRIVED / DROPPED_OFF / ABSENT the driver has ended
  /// the run, and the parent goes back to the passive screen until the next
  /// one starts.
  bool get _runInProgress => _statusByStudent.values.any(
    (s) => s == AttendanceStatus.waiting || s == AttendanceStatus.boarded,
  );

  /// Where the children are resting between runs.
  ///
  /// ARRIVED is the terminal morning status, so any child sitting on it means
  /// the morning run finished and the school day is under way. Absent children
  /// are legitimately at home and do not change the answer — the roster below
  /// names them individually.
  bool get _restingAtSchool => _statusByStudent.entries.any(
    (e) =>
        childLocationFor(
          phase: _phaseByStudent[e.key],
          status: e.value,
        ) ==
        ChildLocation.inSchool,
  );

  /// Which phase the live data belongs to. The afternoon column is only
  /// written once the afternoon run touches the row, so any afternoon phase
  /// means the return leg is the one in progress.
  bool get _isAfternoonRun =>
      _phaseByStudent.values.any((p) => p == 'afternoon');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SocketService.instance.connected.addListener(_onLiveFeedChanged);
    _load();
  }

  @override
  void dispose() {
    SocketService.instance.connected.removeListener(_onLiveFeedChanged);
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _etaSub?.cancel();
    _etaTicker?.cancel();
    for (final id in _joinedRoutes) {
      SocketService.instance.leaveRoute(id);
    }
    super.dispose();
  }

  /// Guards against two catch-ups overlapping — the socket can come back at
  /// the same moment the app does.
  bool _resyncing = false;

  /// Re-reads today's attendance after a gap in the live feed.
  ///
  /// After the first load this screen is driven entirely by socket events, so
  /// anything missed while the feed was down is missed for good: the card goes
  /// on showing "on the bus" long after the child reached school. These are
  /// the two moments we know something may have been missed — the socket
  /// coming back, and the app returning to the foreground.
  Future<void> _resync() async {
    // Before the first load there is nothing to re-sync, and _load() is
    // already on its way.
    if (_resyncing || _students == null) return;
    _resyncing = true;
    try {
      await _pullToRefresh();
    } catch (_) {
      // A failed catch-up must not replace a working screen with an error —
      // the banner already says the feed is down.
    } finally {
      _resyncing = false;
    }
  }

  void _onLiveFeedChanged() {
    if (!mounted) return;
    // Repaint either way so the banner appears and clears with the feed.
    setState(() {});
    // Only fires on a change, so a `true` here is the moment it came back.
    if (SocketService.instance.connected.value) unawaited(_resync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_resync());
  }

  /// Keeps the displayed countdown honest between pings.
  ///
  /// 10s rather than 1s: the label is in whole minutes, so a faster tick would
  /// repaint the card repeatedly for identical text. 10s also bounds how long
  /// a just-expired estimate can keep looking live.
  void _startEtaTicker() {
    _etaTicker ??= Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _etaByRoute.isNotEmpty) setState(() {});
    });
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

      await _refreshStatuses(students);
      await _refreshAbsences();

      _sub ??= SocketService.instance.events.listen(_onEvent);
      _etaSub ??= SocketService.instance.etaEvents.listen(_onEta);
      _startEtaTicker();
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
        _error = errorText(context, e);
      });
    }
  }

  /// Pulls today's attendance for every child in parallel.
  Future<void> _refreshStatuses(List<Student> students) async {
    final results = await Future.wait(
      students.map((s) async {
        try {
          return await ProtectedService.getStudentAttendance(s.id);
        } catch (_) {
          return null; // one child failing must not blank the whole list
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      for (final a in results) {
        if (a == null) continue;
        // Register the id even when the status is still null, so a later
        // `attendance:updated` for this row can be matched. Without this a
        // parent who opens the app mid-run receives live events that silently
        // match nothing.
        _studentByAttendance[a.attendanceId] = a.studentId;
        if (a.currentStatus == null) continue;
        _statusByStudent[a.studentId] = a.currentStatus!;
        _phaseByStudent[a.studentId] = a.currentPhase;
      }
    });
  }

  /// Pulls the upcoming booked mornings for every child at once.
  ///
  /// Silent on failure: this only decorates the roster, and a parent who
  /// cannot reach it must still see where their children are. The sheet
  /// reports its own errors when they actually open it.
  Future<void> _refreshAbsences() async {
    try {
      final window = await AbsenceService.upcoming();
      if (!mounted) return;
      final grouped = <int, List<PlannedAbsence>>{};
      for (final absence in window.absences) {
        grouped.putIfAbsent(absence.studentId, () => []).add(absence);
      }
      for (final days in grouped.values) {
        days.sort((a, b) => a.date.compareTo(b.date));
      }
      setState(() => _absencesByStudent = grouped);
    } catch (_) {
      // Leave whatever was already shown rather than blanking the badges.
    }
  }

  /// Whether this morning's run is already behind us for [studentId].
  ///
  /// Read off the child's own attendance rather than the clock: once the
  /// morning status has settled on arrived or absent, or the afternoon leg has
  /// begun, that morning cannot be changed any more. Passed to the sheet so it
  /// strikes today out instead of offering a booking that would do nothing.
  bool _morningOver(int studentId) {
    if (_phaseByStudent[studentId] == 'afternoon') return true;
    final status = _statusByStudent[studentId];
    return status == AttendanceStatus.arrived ||
        status == AttendanceStatus.absent;
  }

  /// Opens the per-child sheet and reloads only what actually moved.
  Future<void> _openAbsenceSheet(Student student) async {
    final outcome = await PrAbsenceSheet.show(
      context,
      studentId: student.id,
      studentName: student.firstName,
      morningOver: _morningOver(student.id),
    );
    if (!outcome.changed || !mounted) return;

    await _refreshAbsences();

    // Attendance is only re-fetched when a run was actually under way. A
    // booking for a future morning cannot have moved anyone's status today,
    // and refreshing anyway costs one request per child that the backend
    // answers 404 and logs as an error.
    if (!outcome.statusChanged) return;
    final students = _students;
    if (students != null) await _refreshStatuses(students);
  }

  /// Warns that what follows may have moved on without us.
  ///
  /// Null while the feed is up, and while the first load is still running —
  /// the skeleton already says the screen is not ready.
  Widget? _staleFeedBanner(AppLocalizations l10n) {
    if (SocketService.instance.connected.value || _students == null) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warningTint,
          border: AppBorders.card,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          spacing: 8,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 18),
            Expanded(
              child: Text(
                l10n.liveUpdatesPaused,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pullToRefresh() async {
    final students = _students;
    if (students != null && students.isNotEmpty) {
      await Future.wait([_refreshStatuses(students), _refreshAbsences()]);
    } else {
      await _load();
    }
  }

  void _onEta(RouteEta eta) {
    if (kDebugMode) {
      debugPrint(
        '[eta] route=${eta.routeId} phase=${eta.phase} '
        'confidence=${eta.lowConfidence ? "low" : "normal"} '
        'stops=${eta.byStudent.keys.toList()} '
        'joined=$_joinedRoutes',
      );
    }
    // A parent with children on two routes receives both rooms' estimates on
    // the same stream; keep only the one covering a route we are watching.
    if (!mounted || !_joinedRoutes.contains(eta.routeId)) return;
    setState(() => _etaByRoute[eta.routeId] = eta);
  }

  void _onEvent(AttendanceEvent event) {
    final students = _students;
    if (students == null || !mounted) return;

    setState(() {
      switch (event.type) {
        case AttendanceEventType.morningStarted:
        case AttendanceEventType.morningCompleted:
          _applyRoster(students, event, 'morning');
        case AttendanceEventType.afternoonStarted:
        case AttendanceEventType.afternoonCompleted:
          _applyRoster(students, event, 'afternoon');
        case AttendanceEventType.studentUpdated:
          final studentId = _studentByAttendance[event.attendanceId];
          final status = event.newStatus;
          if (studentId != null && status != null) {
            _statusByStudent[studentId] = status;
            if (event.phase != null) _phaseByStudent[studentId] = event.phase!;
          }
      }
    });
  }

  void _applyRoster(
    List<Student> students,
    AttendanceEvent event,
    String phase,
  ) {
    final mine = students.map((s) => s.id).toSet();
    for (final rosterStudent in event.students) {
      if (!mine.contains(rosterStudent.studentId)) continue;
      _studentByAttendance[rosterStudent.attendanceId] =
          rosterStudent.studentId;
      _statusByStudent[rosterStudent.studentId] = rosterStudent.status;
      _phaseByStudent[rosterStudent.studentId] = phase;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final students = _students;

    // Skeleton, empty state and content cross-fade rather than snapping, so
    // a fast response does not flash a skeleton and a slow one does not slam
    // the roster into place.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: _content(context, l10n, students),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    List<Student>? students,
  ) {
    if (students == null) {
      return CmSkeleton.parentStatusPage();
    }

    if (students.isEmpty) {
      return _error != null
          ? CmStateView.error(
              key: const ValueKey('error'),
              message: _error!,
              actionLabel: l10n.retry,
              onAction: _load,
            )
          : CmStateView.empty(
              key: const ValueKey('empty'),
              icon: Icons.child_care,
              message: l10n.noStudentsLinked,
              actionLabel: l10n.retry,
              onAction: _load,
            );
    }

    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: _pullToRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ---- Status: where the trip itself stands ----
          CmSectionHeader(l10n.status),
          // Everything below this is only as fresh as the live feed. Saying so
          // is the difference between "the bus has not moved" and "we stopped
          // being told where it is".
          ?_staleFeedBanner(l10n),
          // A run starting swaps a quiet card for a live one. Crossfading with
          // a small rise makes that read as the screen coming to life rather
          // than a jump cut.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            // Sized to the incoming child so the list does not jerk while the
            // taller trip card grows in.
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: _runInProgress
                ? PrTripProgressWidget(
                    key: const ValueKey('trip-progress'),
                    afternoon: _isAfternoonRun,
                    // Estimates only exist as broadcasts, so there is a gap
                    // between opening the app mid-run and the next ping.
                    awaitingFirstEstimate: _etaByRoute.isEmpty,
                    eta: _tripEta,
                    children: [
                      for (final s in students)
                        TripProgressChild(
                          name: s.firstName,
                          location: childLocationFor(
                            phase: _phaseByStudent[s.id],
                            status: _statusByStudent[s.id],
                          ),
                          absent:
                              _statusByStudent[s.id] == AttendanceStatus.absent,
                          // The roster below is hidden during a run, so this
                          // is the only way to reach the sheet while the bus
                          // is out — which is exactly when a parent needs it.
                          onTap: () => _openAbsenceSheet(s),
                        ),
                    ],
                  )
                : PrStatusPagePassive(
                    key: const ValueKey('passive'),
                    atSchool: _restingAtSchool,
                  ),
          ),

          // ---- Per-child roster, only between runs. While a run is under
          // way the trip card above already lists every child with their
          // position on the track, so repeating them here says the same thing
          // twice and pushes the live information off the screen. ----
          if (!_runInProgress) ...[
            CmSectionHeader(l10n.studentStatus),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: AppBorders.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  spacing: 10,
                  children: [
                    for (final student in students)
                      _studentRow(context, student),
                  ],
                ),
              ),
            ),
          ],

          // ---- Support, only while a trip is running: that is when a parent
          // has something to ask about. Between runs it is on the profile. ----
          if (_runInProgress && widget.trailing != null) ...[
            CmSectionHeader(l10n.support),
            widget.trailing!,
          ],
        ],
      ),
    );
  }

  Widget _studentRow(BuildContext context, Student student) {
    final l10n = AppLocalizations.of(context)!;

    // No record for today means no run has collected them: they are at home.
    final location =
        childLocationFor(
          phase: _phaseByStudent[student.id],
          status: _statusByStudent[student.id],
        ) ??
        ChildLocation.atHome;
    final label = childLocationLabel(context, location);

    final booked = _absencesByStudent[student.id] ?? const <PlannedAbsence>[];

    // The whole row is the control. A separate icon button would put two
    // targets on one line and make the quiet, common case (just reading where
    // the child is) feel like a menu.
    return Semantics(
      button: true,
      label: '${student.firstName}. $label',
      hint: l10n.manageAbsence,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: () => _openAbsenceSheet(student),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderGray),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 14),
                  child: Icon(Icons.child_care, size: 26),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        student.firstName,
                        style: const TextStyle(fontSize: 18),
                      ),
                      // Says the booking exists without making the parent
                      // open anything to find out.
                      if (booked.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _bookedSummary(context, booked),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _locationChip(location, label),
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 6),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationChip(ChildLocation location, String label) {
    return Container(
      decoration: BoxDecoration(
        color: childLocationColor(location),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(childLocationIcon(location), size: 15),
          Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// "Not riding · 12 Sep" for one day, "Not riding · 3 mornings" beyond that.
  ///
  /// Deliberately not a Mon–Wed range: the booked days need not be contiguous,
  /// and a range label would quietly imply the gap days are booked too.
  String _bookedSummary(BuildContext context, List<PlannedAbsence> booked) {
    final l10n = AppLocalizations.of(context)!;
    if (booked.length > 1) {
      return '${l10n.absenceSkippedChip} · ${l10n.absenceMorningsCount(booked.length)}';
    }
    final parts = booked.first.date.split('-');
    if (parts.length != 3) return l10n.absenceSkippedChip;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return l10n.absenceSkippedChip;
    }
    // Noon, so formatting cannot tip the label over a day boundary.
    final text = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime(year, month, day, 12));
    return '${l10n.absenceSkippedChip} · $text';
  }
}
