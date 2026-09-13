import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/attendance_status_ui.dart';
import 'package:mockup/Util/calendar_date.dart';
import 'package:mockup/Util/error_text.dart';
import 'package:mockup/Util/toast.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_section_header.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_state_view.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_broadcast_status.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_route_map.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_student_card.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_today_card.dart';
import 'package:mockup/services/api_client.dart';
import 'package:mockup/services/attendance_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_location_diagnostics.dart';
import 'package:mockup/services/driver_location_reporter.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:mockup/services/protected_service.dart';
import 'package:mockup/services/route_service.dart';

import '../../l10n/app_localizations.dart';

/// Which run the wall clock currently allows. The driver no longer picks:
/// 06:00-08:59 is the morning run, 13:00-15:59 the afternoon run, anything
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

  // Which run the driver has picked by hand. Null means the clock decides
  // (see [runWindowFor]). Available in release builds too: the time windows
  // are a client-side convenience, and a driver whose run falls outside them
  // (early start, late finish, a one-off trip) still has to be able to work.
  // The backend remains the real gate, e.g. the afternoon run is refused
  // until the morning one is completed.
  RunWindow? _manualWindow;

  RunWindow get _effectiveWindow => _manualWindow ?? _window;

  // Frozen at start time so a run that crosses 9:00/16:00 keeps calling the
  // endpoints of the phase it was started in.
  bool _isAfternoon = false;

  RouteStart? _run;

  /// Set when the driver taps Back out of an active run. The run itself is
  /// kept in memory rather than discarded: it is still IN_PROGRESS on the
  /// server, and the Start button is disabled outside its time window, so
  /// clearing it here would leave a driver unable to re-enter or finish a run
  /// that overran the window. Resume just flips this back.
  bool _viewingPassive = false;

  bool _droppingOff = false;

  /// Absent students the driver has already been shown and dismissed.
  ///
  /// A parent's declaration reaches the driver as a status, not a message, so
  /// the run surfaces each absent child in travel order and waits to be
  /// acknowledged — otherwise the only sign is a stop that silently never
  /// appears. Held in memory rather than on the server: nothing depends on it
  /// being durable, and losing it on a restart re-shows the card, which is the
  /// safe direction to fail.
  final Set<int> _acknowledgedAbsent = {};

  final Set<int> _busyIds = {};
  bool _working = false;
  String? _loadError;

  /// Today's attendance for the selected route, powering [DvTodayCard].
  /// One request against the endpoint History already uses.
  TripSession? _today;
  bool _todayLoading = false;

  /// studentId -> position along the route, from the route's waypoints.
  ///
  /// The server returns the afternoon roster ordered by student id, which has
  /// no relationship to where anyone lives: on route 1 that is route
  /// positions 2, 3, 1, 4, 5. Presenting drop-offs in that order sends the
  /// driver up and down the route and makes the map tick off stops in what
  /// looks like a random sequence. Ordering is therefore done here, against
  /// the geometry, rather than trusting the order rows arrive in.
  Map<int, int> _stopOrder = const {};

  /// The run's students in the order the bus actually reaches them.
  ///
  /// Morning follows the waypoints; the afternoon runs the same line
  /// backwards, so it is the exact reverse. A student with no waypoint keeps
  /// their relative position at the end rather than vanishing — the roster is
  /// the driver's checklist and dropping someone from it loses a child.
  List<AttendanceStudent> _inTravelOrder(List<AttendanceStudent> students) {
    if (_stopOrder.isEmpty) return students;
    final ordered = [...students];
    ordered.sort((a, b) {
      final sa = _stopOrder[a.studentId];
      final sb = _stopOrder[b.studentId];
      if (sa == null && sb == null) return 0;
      if (sa == null) return 1;
      if (sb == null) return -1;
      return _isAfternoon ? sb.compareTo(sa) : sa.compareTo(sb);
    });
    return ordered;
  }

  /// Pulls the waypoint order for the route being driven.
  ///
  /// Failure is silent and non-blocking: without it the roster falls back to
  /// whatever order the server sent, which is what shipped before. A driver
  /// must still be able to work when the map data cannot be fetched.
  Future<void> _loadStopOrder(int routeId) async {
    try {
      final map = await RouteService.getDriverRoute(routeId);
      if (!mounted) return;
      setState(() {
        _stopOrder = {
          for (final w in map.waypoints)
            if (w.studentId != null) w.studentId!: w.sortNumber,
        };
      });
    } catch (_) {
      // Keep the server's order rather than failing the run.
    }
  }

  /// Students whose stop the map should show as done, so the pins renumber
  /// as the run progresses.
  ///
  /// What counts as done depends on the leg being driven: in the morning the
  /// stop is the pickup, so anything past WAITING (boarded, or absent and not
  /// coming) is finished with. In the afternoon the stop is the delivery, so
  /// a BOARDED student is still on the bus and their stop is very much
  /// outstanding — only DROPPED_OFF or ABSENT clears it.
  Set<int> get _servedStudentIds {
    final students = _run?.students;
    if (students == null) return const {};
    return {
      for (final s in students)
        if (_isAfternoon
            ? (s.status == AttendanceStatus.droppedOff ||
                  s.status == AttendanceStatus.absent)
            : s.status != AttendanceStatus.waiting)
          s.studentId,
    };
  }

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
    DriverLocationReporter.instance.stop();
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
      await _loadToday();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routes = const [];
        _loadError = errorText(context, e);
      });
    }
  }

  /// Pulls today's attendance for the selected route.
  ///
  /// Deliberately silent on failure: this card is a convenience, and a driver
  /// who cannot reach it must still be able to start a run. The primary
  /// path already reports its own errors.
  Future<void> _loadToday() async {
    final route = _selectedRoute;
    if (route == null) return;
    setState(() => _todayLoading = true);
    try {
      final today = DateTime.now();
      final records = await AttendanceService.attendanceOn(route.id, today);
      if (!mounted) return;
      setState(() {
        _today = TripSession(
          date: formatCalendarDate(today),
          day: DateTime(today.year, today.month, today.day),
          records: records,
        );
      });
    } catch (_) {
      if (mounted) setState(() => _today = null);
    } finally {
      if (mounted) setState(() => _todayLoading = false);
    }
  }

  /// A run the server still has open that this app instance knows nothing
  /// about, derived from today's attendance rather than from run events.
  ///
  /// WAITING and BOARDED are the only non-terminal statuses in either phase,
  /// so their presence means the driver started a run and never finished it.
  RunWindow? get _unresumedRun {
    if (_run != null) return null;
    final records = _today?.records;
    if (records == null || records.isEmpty) return null;

    bool open(String? status) =>
        status == AttendanceStatus.waiting ||
        status == AttendanceStatus.boarded;

    if (records.any((r) => open(r.afternoonStatus))) return RunWindow.afternoon;
    if (records.any((r) => open(r.morningStatus))) return RunWindow.morning;
    return null;
  }

  /// Re-enters a run the app lost track of.
  ///
  /// The start endpoints are idempotent — re-entering an IN_PROGRESS run
  /// returns the current roster rather than resetting anyone — so this is the
  /// same call as starting, and it is what restarts location reporting.
  Future<void> _resumeRun() async {
    final phase = _unresumedRun;
    if (phase == null) return;
    setState(() => _manualWindow = phase);
    await _confirmLocationAndStart();
  }

  /// Explains the location use immediately before the system permission
  /// prompt, and then always lets that prompt happen.
  ///
  /// App Store guideline 5.1.1(iv): a custom message shown ahead of the system
  /// prompt must always proceed to it. An earlier version offered "Not now",
  /// which dismissed the explanation and postponed the request indefinitely —
  /// that is what the app was rejected for. There is now a single action, the
  /// dialog cannot be dismissed around, and it is only raised when a request
  /// will genuinely follow.
  ///
  /// It is still our own wording rather than the system prompt alone, because
  /// Play's prominent-disclosure rule requires stating that a live run sends
  /// the driver's position to Masar Alburhan in the background — which the
  /// system prompt does not say. Declining still belongs to the driver; it
  /// just happens in the system prompt, where the decision is actually made.
  Future<void> _confirmLocationAndStart() async {
    if (_working || _selectedRoute == null || _effectiveWindow == RunWindow.none) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;

    // Already granted: no prompt is coming, so a message introducing one would
    // be describing something that never happens.
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _startRun();
      return;
    }

    // The OS will not ask again. Showing the disclosure would promise a prompt
    // that cannot appear, so point at the one place the decision can still be
    // changed — which is also Apple's suggested remedy.
    if (permission == LocationPermission.deniedForever) {
      await _showLocationBlocked(l10n);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        // Without this the Android back gesture becomes the "Not now" the
        // guideline forbids.
        canPop: false,
        child: AlertDialog(
          icon: const Icon(
            Icons.location_on_outlined,
            color: AppColors.deepNavy,
          ),
          title: Text(l10n.locationDisclosureTitle),
          content: Text(l10n.locationDisclosureMessage),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    // Unconditional: the system prompt follows the message every time.
    await _startRun();
  }

  /// Permission was permanently denied, so nothing this app does will raise a
  /// prompt again. Offer the only route left rather than failing silently.
  Future<void> _showLocationBlocked(AppLocalizations l10n) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.location_off_outlined,
          color: AppColors.dangerRed,
        ),
        title: Text(l10n.locationBlockedTitle),
        content: Text(l10n.locationBlockedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
    if (open == true) await Geolocator.openAppSettings();
  }

  Future<void> _startRun() async {
    final l10n = AppLocalizations.of(context)!;
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
        _viewingPassive = false;
        _acknowledgedAbsent.clear();
      });
      // The roster's order depends on the route's geometry, so fetch it
      // alongside starting the run rather than waiting for the map to open.
      _loadStopOrder(route.id);
      // Reports for the whole run, independent of whether the map is open,
      // and keeps going once the screen locks.
      DriverLocationReporter.instance.start(
        route.id,
        notificationTitle: l10n.trackingNotificationTitle,
        notificationText: l10n.trackingNotificationText,
      );
    } on ApiException catch (e) {
      _showError(e);
    } catch (_) {
      _showConnectionError();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Attempts a write beyond the first before the driver is told it failed.
  ///
  /// A route runs through dead spots, and the old behaviour — fail instantly,
  /// show a red snackbar — asked the driver to notice it and tap again while
  /// driving. The action button holds its spinner for the duration, so this is
  /// a visibly slow write rather than a silent one.
  ///
  /// ponytail: in-memory only — a mark tapped during a long outage still fails
  /// and is re-tapped by hand, and killing the app drops anything in flight.
  /// Add a persisted queue if drivers report losing marks, not before.
  static const int _writeRetries = 3;
  static const Duration _retryBackoff = Duration(seconds: 2);

  /// Whether a failure says anything about the request itself.
  ///
  /// No answer at all (no signal, timeout), a proxy error page, or a 5xx are
  /// all "ask again later". A 403/404/409 is the server giving a real verdict,
  /// and repeating it only delays telling the driver.
  static bool _worthRetrying(Object error) {
    if (error is! ApiException) return true;
    return error.kind == ApiErrorKind.network ||
        error.kind == ApiErrorKind.badResponse ||
        error.kind == ApiErrorKind.server;
  }

  /// Retries [action] on transient failures, backing off between attempts.
  ///
  /// Safe because every attendance endpoint is idempotent: a retry of a
  /// request that actually landed comes back `changed:false` rather than
  /// applying twice.
  Future<T> _withRetry<T>(Future<T> Function() action) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await action();
      } catch (e) {
        if (attempt >= _writeRetries || !_worthRetrying(e) || !mounted) {
          rethrow;
        }
        await Future<void>.delayed(_retryBackoff * (attempt + 1));
      }
    }
  }

  Future<void> _transition(
    AttendanceStudent student,
    Future<AttendanceUpdate> Function(int attendanceId) call,
  ) async {
    if (_busyIds.contains(student.attendanceId)) return;
    setState(() => _busyIds.add(student.attendanceId));
    try {
      final result = await _withRetry(() => call(student.attendanceId));
      if (!mounted) return;
      // Confirm by feel: the driver is often not looking at the screen.
      HapticFeedback.mediumImpact();
      setState(() {
        student.status = result.newStatus;
        // A driver marking someone absent has just decided it themselves —
        // re-presenting the "not riding today" card for confirmation would be
        // double work. That card is only for a parent's declaration, which
        // reaches the cab as a status with no other announcement; a driver's
        // own mark is self-explanatory, so treat it as already seen.
        if (result.newStatus == AttendanceStatus.absent) {
          _acknowledgedAbsent.add(student.attendanceId);
        }
      });
      // Absent is the one transition that is costly to get wrong, and it can
      // be triggered by an accidental swipe on a moving bus. Offer a reversal
      // rather than a modal, which would be worse to dismiss while driving.
      if (result.changed && result.newStatus == AttendanceStatus.absent) {
        _offerUndo(student);
      }
    } on ApiException catch (e) {
      _showError(e);
    } catch (_) {
      _showConnectionError();
    } finally {
      if (mounted) setState(() => _busyIds.remove(student.attendanceId));
    }
  }

  /// Reverses an ABSENT mark by boarding the student again, using whichever
  /// phase endpoint the current run belongs to.
  void _offerUndo(AttendanceStudent student) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.markedAbsent(student.firstName)),
          duration: const Duration(seconds: 6),
          // Required: SnackBar.persist defaults to `action != null`, so any
          // snackbar with an action stays on screen forever and [duration] is
          // ignored. The driver must not have to dismiss this by hand while
          // driving — it expires on its own and the mark simply stands.
          persist: false,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => _transition(
              student,
              _isAfternoon
                  ? AttendanceService.boardAfternoon
                  : AttendanceService.boardMorning,
            ),
          ),
        ),
      );
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
            child: Text(l10n.cancel),
          ),
          // Red marks the irreversible choice, not the way out of it. These
          // were the wrong way round, which is how a driver taps the red one
          // to back out and finalizes the run instead.
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.ok,
              style: const TextStyle(color: AppColors.dangerRed),
            ),
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
        _viewingPassive = false;
        _acknowledgedAbsent.clear();
      });
      // The run is over: the backend would refuse further pings anyway, and
      // tracking a driver off the clock is exactly what we do not do.
      DriverLocationReporter.instance.stop();
      _showSummary(summary);
    } on ApiException catch (e) {
      _showError(e);
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

  /// Localizes and shows a caught error.
  ///
  /// Takes the error rather than a finished string so the `mounted` check
  /// happens before anything touches `context` — every caller is on the far
  /// side of an `await`, and resolving the message first would use a
  /// BuildContext that may already be gone.
  void _showError(Object error) {
    if (!mounted) return;
    showToast(context, errorText(context, error), error: true);
  }

  void _showConnectionError() {
    if (!mounted) return;
    showToast(context, AppLocalizations.of(context)!.connectionError,
        error: true);
  }

  @override
  Widget build(BuildContext context) {
    final routes = _routes;
    if (routes == null) {
      return CmSkeleton.driverStatusPage();
    }
    final Widget child;
    if (_run == null || _viewingPassive) {
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
      return _loadError != null
          ? CmStateView.error(
              key: const ValueKey('empty'),
              message: _loadError!,
              actionLabel: l10n.retry,
              onAction: _loadRoutes,
            )
          : CmStateView.empty(
              key: const ValueKey('empty'),
              icon: Icons.directions_bus_filled_outlined,
              message: l10n.noRoutesAssigned,
              actionLabel: l10n.retry,
              onAction: _loadRoutes,
            );
    }

    final window = _effectiveWindow;
    return RefreshIndicator(
      onRefresh: () async {
        await _loadRoutes();
        await _loadToday();
      },
      child: ListView(
        key: const ValueKey('passive'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _greeting(l10n),

          // ---- The run itself: which route, which leg, and the way in. ----
          CmSectionHeader(l10n.myRoute),
          _routeCard(l10n, routes, window),

          // ---- What has already happened today. Answers "have I done the
          // morning run?" without a trip into History. ----
          CmSectionHeader(l10n.todayAtAGlance),
          DvTodayCard(session: _today, loading: _todayLoading),

          // ---- The route itself, collapsed. Lets the driver review stops
          // before starting rather than only once under way.
          //
          // No section header: unlike the cards above, this one is a
          // disclosure control that already carries its own label, and
          // "ROUTE MAP" over "Route map" is the duplication the section
          // pattern exists to remove. ----
          if (_selectedRoute != null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: DvRouteMap(
                key: ValueKey('passive-map-${_selectedRoute!.id}'),
                routeId: _selectedRoute!.id,
              ),
            ),
        ],
      ),
    );
  }

  /// Time-of-day greeting with the driver's first name.
  ///
  /// Free: the name is already in the restored session, and the greeting is
  /// pure clock arithmetic. It costs nothing and makes the idle screen read
  /// as a home rather than a form.
  Widget _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning
        : hour < 17
        ? l10n.greetingAfternoon
        : l10n.greetingEvening;
    final name = AuthSession.instance.user?.firstName.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        name.isEmpty ? greeting : '$greeting, $name',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.deepNavy,
        ),
      ),
    );
  }

  Widget _routeCard(
    AppLocalizations l10n,
    List<DriverRoute> routes,
    RunWindow window,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: AppColors.deepNavy,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          // No "My route" label inside the card: the section header above it
          // now carries that, exactly as the parent roster's heading replaced
          // its in-card title.
          if (routes.length == 1)
            Row(
              children: [
                const Icon(
                  Icons.directions_bus_filled_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    routes.first.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          else
            DropdownButton<DriverRoute>(
              value: _selectedRoute,
              dropdownColor: AppColors.deepNavy,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              items: [
                for (final r in routes)
                  DropdownMenuItem(value: r, child: Text(r.name)),
              ],
              onChanged: (r) => setState(() => _selectedRoute = r),
            ),
          _buildRunWindowBanner(l10n, window),
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
            onSelectionChanged: (s) =>
                setState(() => _manualWindow = s.isEmpty ? null : s.first),
            style: SegmentedButton.styleFrom(backgroundColor: Colors.white),
          ),
          // A run left via Back is still running: offer the way back into
          // it instead of Start. Deliberately not gated on the time
          // window, so a run that overran its window can still be
          // reopened and completed.
          //
          // The same button covers a run the app has lost track of entirely
          // (a restart, a crash, the process being reaped mid-route). That
          // case is the dangerous one: the run is still IN_PROGRESS on the
          // server but location reporting died with the old process, so the
          // bus goes dark until someone notices.
          // Say why Resume is being offered when the app has no memory of the
          // run — otherwise it reads as a stray button.
          if (_run == null && _unresumedRun != null)
            Row(
              spacing: 8,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: Colors.white70,
                ),
                Expanded(
                  child: Text(
                    l10n.runInProgressNotice,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          if (_run != null || _unresumedRun != null)
            ElevatedButton.icon(
              onPressed: _working
                  ? null
                  : _run != null
                  ? () => setState(() => _viewingPassive = false)
                  : _resumeRun,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
              ),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l10n.resumeRun.toUpperCase()),
            )
          else
            ElevatedButton.icon(
              onPressed: _working || window == RunWindow.none
                  ? null
                  : _confirmLocationAndStart,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
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
    );
  }

  /// "Starts in 2h 14m" for the next run window today, or null once both
  /// windows have passed (the caller then falls back to the schedule text).
  ///
  /// The one-minute clock in [initState] already rebuilds this page, so the
  /// countdown stays current without a second timer.
  String? _timeUntilNextWindow(AppLocalizations l10n) {
    final now = DateTime.now();
    // Window starts, in the order they occur (see [runWindowFor]).
    for (final startHour in const [6, 13]) {
      final start = DateTime(now.year, now.month, now.day, startHour);
      if (start.isAfter(now)) {
        final left = start.difference(now);
        final h = left.inHours;
        final m = left.inMinutes.remainder(60);
        final pretty = h > 0
            ? l10n.hoursMinutesShort(h, m)
            : l10n.minutesShort(m);
        return l10n.nextRunIn(pretty);
      }
    }
    return null;
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
          borderRadius: BorderRadius.circular(AppRadius.control),
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
              // "Starts in 2h 14m" beats the raw 06:00–09:00 / 13:00–16:00
              // schedule: it answers the question the driver actually has.
              // Falls back to the schedule after the last window of the day.
              _timeUntilNextWindow(l10n) ?? l10n.runWindowsInfo,
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
        borderRadius: BorderRadius.circular(AppRadius.control),
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
        _backBar(l10n),
        _reportingBanner(l10n),
        if (kLocationDiagnostics) const DvLocationDiagnostics(),
        if (_selectedRoute != null)
          DvRouteMap(
            key: ValueKey('map-${_selectedRoute!.id}'),
            routeId: _selectedRoute!.id,
            servedStudentIds: _servedStudentIds,
            afternoon: _isAfternoon,
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 25, top: 15),
          child: Text(
            '${l10n.afternoonRun} - ${l10n.attendanceTitle}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 25,
            bottom: 5,
            end: 25,
          ),
          child: Text(
            l10n.attendanceHint,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        for (final student in _inTravelOrder(run.students))
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
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.startDropoffs.toUpperCase()),
          ),
        ),
        if (kBroadcastStatusEnabled) const DvBroadcastStatus(),
      ],
    );
  }

  /// Morning active page: one waiting student at a time, dropoff-page card
  /// style. Boarding at pickup counts as attendance; already-handled
  /// students stay listed below with a toggle so mistakes are correctable.
  Widget _buildPickup() {
    final l10n = AppLocalizations.of(context)!;
    final run = _run!;
    final ordered = _inTravelOrder(run.students);

    // Absent children stay in the queue until the driver has seen them.
    // Filtering them out here is what used to make a parent's declaration
    // invisible in the cab: the stop simply never came up, and a child who
    // turned up anyway had nowhere to be boarded from.
    bool outstanding(AttendanceStudent s) =>
        s.status == AttendanceStatus.waiting ||
        (s.status == AttendanceStatus.absent &&
            !_acknowledgedAbsent.contains(s.attendanceId));

    final queue = ordered.where(outstanding).toList();
    final handled = ordered.where((s) => !outstanding(s)).toList();

    // The count is pickups, not stops, so an absent child is not one of them.
    final remaining = queue
        .where((s) => s.status == AttendanceStatus.waiting)
        .length;

    return ListView(
      key: const ValueKey('pickup'),
      children: [
        ..._runHeader(l10n),
        ..._runTitle(
          '${l10n.morningRun} - ${l10n.nextPickup}',
          l10n.pickupRemaining(remaining),
        ),
        if (queue.isEmpty)
          _buildAllDoneCard(l10n.allPickedUp)
        else ...[
          if (queue.first.status == AttendanceStatus.absent)
            _buildAbsentStudentCard(l10n, queue.first)
          else
            _buildNextStudentCard(
              queue.first,
              actionLabel: l10n.board,
              actionIcon: Icons.directions_bus_filled,
              onAction: () =>
                  _transition(queue.first, AttendanceService.boardMorning),
              secondaryLabel: l10n.absent,
              onSecondary: () =>
                  _transition(queue.first, AttendanceService.absentMorning),
            ),
          if (queue.length > 1) ...[
            CmSubsectionHeader(l10n.upNext),
            for (final student in queue.skip(1)) _upNextRow(student),
          ],
        ],
        if (handled.isNotEmpty) ...[
          CmSubsectionHeader(l10n.studentsTitle),
          for (final student in handled) _handledRow(student),
        ],
        ..._runTail(l10n),
      ],
    );
  }

  /// Compact row for a boarded/absent student on the pickup page with a
  /// single toggle to flip the status if it was a mistake.
  Widget _handledRow(AttendanceStudent student) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _busyIds.contains(student.attendanceId);
    final absent = student.status == AttendanceStatus.absent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsetsDirectional.only(start: 15, end: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(
            absent ? Icons.person_off_outlined : Icons.child_care,
            size: 22,
            color: absent ? AppColors.dangerRed : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: Text(
                student.firstName,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: attendanceStatusColor(student.status),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              attendanceStatusLabel(context, student.status).toUpperCase(),
              // Spoken in normal case: screen readers spell out all-caps.
              semanticsLabel: attendanceStatusLabel(context, student.status),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
              tooltip: absent ? l10n.board : l10n.absent,
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

  /// Leaves the active run without ending it. The run keeps running on the
  /// server; [_buildPassive] offers Resume to come straight back.
  Widget _backBar(AppLocalizations l10n) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, top: 8),
        child: TextButton.icon(
          onPressed: () => setState(() => _viewingPassive = true),
          icon: const Icon(Icons.arrow_back, size: 20),
          label: Text(l10n.back),
        ),
      ),
    );
  }

  /// Warns the driver when their position has stopped reaching the server.
  ///
  /// Without this the failure is invisible: the ongoing notification still
  /// says a run is in progress, the screen looks normal, and nobody learns
  /// the bus went dark until someone asks where it was.
  Widget _reportingBanner(AppLocalizations l10n) {
    return ValueListenableBuilder<bool>(
      valueListenable: DriverLocationReporter.instance.reporting,
      builder: (context, reporting, _) {
        if (reporting) return const SizedBox.shrink();
        // Two very different failures land here and the driver can only act on
        // one of them. "Not reaching the server" is a connectivity problem
        // they can do nothing about from this screen; reduced accuracy is a
        // switch in Settings, so it gets its own wording and a way there.
        return ValueListenableBuilder<bool>(
          valueListenable: DriverLocationReporter.instance.reducedAccuracy,
          builder: (context, reduced, _) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.dangerTint,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                spacing: 10,
                children: [
                  Icon(
                    reduced ? Icons.location_disabled : Icons.cloud_off,
                    size: 20,
                  ),
                  Expanded(
                    child: Text(
                      reduced
                          ? l10n.locationReducedAccuracy
                          : l10n.locationNotReporting,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (reduced)
                    TextButton(
                      onPressed: Geolocator.openAppSettings,
                      child: Text(l10n.openSettings),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// What every run page opens with: the way back, the reporting banner, and
  /// the map of where the bus is.
  List<Widget> _runHeader(AppLocalizations l10n) => [
    _backBar(l10n),
    _reportingBanner(l10n),
    if (kLocationDiagnostics) const DvLocationDiagnostics(),
    if (_selectedRoute != null)
      DvRouteMap(
        key: ValueKey('map-${_selectedRoute!.id}'),
        routeId: _selectedRoute!.id,
        servedStudentIds: _servedStudentIds,
        afternoon: _isAfternoon,
      ),
  ];

  /// The run page's title and the count line under it.
  List<Widget> _runTitle(String title, String subtitle) => [
    Padding(
      padding: const EdgeInsetsDirectional.only(start: 25, top: 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    Padding(
      padding: const EdgeInsetsDirectional.only(start: 25, bottom: 5),
      child: Text(subtitle, style: const TextStyle(color: Colors.grey)),
    ),
  ];

  /// What every run page closes with.
  List<Widget> _runTail(AppLocalizations l10n) => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: _completeRunButton(l10n),
    ),
    if (kBroadcastStatusEnabled) const DvBroadcastStatus(),
  ];

  Widget _upNextRow(AttendanceStudent student) {
    final l10n = AppLocalizations.of(context)!;
    // Same amber as the card, so a stop the driver will be told to skip reads
    // that way while it is still further down the list.
    final absent = student.status == AttendanceStatus.absent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: absent ? AppColors.warningTint : AppColors.surfaceMuted,
        border: Border.all(
          color: absent ? AppColors.warningYellow : AppColors.borderGray,
        ),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(
            absent ? Icons.person_off_outlined : Icons.child_care,
            size: 22,
          ),
          Expanded(
            child: Text(
              student.firstName,
              style: TextStyle(
                fontSize: 16,
                decoration: absent ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (absent)
            Text(
              l10n.driverNotRiding.toUpperCase(),
              semanticsLabel: l10n.driverNotRiding,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllDoneCard(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        spacing: 10,
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
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
    final boarded = _inTravelOrder(run.students)
        .where((s) => s.status == AttendanceStatus.boarded)
        .toList();

    return ListView(
      key: const ValueKey('dropoff'),
      children: [
        ..._runHeader(l10n),
        ..._runTitle(
          '${l10n.afternoonRun} - ${l10n.nextDropoff}',
          l10n.dropoffRemaining(boarded.length),
        ),
        if (boarded.isEmpty)
          _buildAllDoneCard(l10n.allDroppedOff)
        else ...[
          _buildNextStudentCard(
            boarded.first,
            actionLabel: l10n.dropoff,
            actionIcon: Icons.done,
            onAction: () =>
                _transition(boarded.first, AttendanceService.dropoffAfternoon),
          ),
          if (boarded.length > 1) ...[
            CmSubsectionHeader(l10n.upNext),
            for (final student in boarded.skip(1)) _upNextRow(student),
          ],
        ],
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 20,
            end: 20,
            top: 10,
          ),
          child: TextButton.icon(
            onPressed: () => setState(() => _droppingOff = false),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(l10n.backToAttendance),
          ),
        ),
        ..._runTail(l10n),
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
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(AppRadius.card),
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
              foregroundColor: AppColors.deepNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade200),
              icon: const Icon(Icons.person_off_outlined, size: 20),
              label: Text(secondaryLabel),
            ),
        ],
      ),
    );
  }

  /// The stop the driver must NOT wait at.
  ///
  /// Deliberately inverted against [_buildNextStudentCard]: that card is a
  /// dark navy panel, this one is a pale amber panel with an outline. A driver
  /// glancing down at a moving bus reads the block of colour before any word
  /// on it, so "pick this child up" and "drive past this child" cannot be the
  /// same shape in the same colour with different text.
  ///
  /// Amber rather than red on purpose. Nothing has gone wrong — a parent said
  /// the child is not riding — and red is already the colour this screen uses
  /// for the destructive marks the driver makes themselves.
  ///
  /// Boarding stays available. The declaration is advisory, the server accepts
  /// boarding from any status, and a child who turns up regardless must not be
  /// left at the kerb because the app has no button for them.
  Widget _buildAbsentStudentCard(
    AppLocalizations l10n,
    AttendanceStudent student,
  ) {
    final busy = _busyIds.contains(student.attendanceId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        border: Border.all(color: AppColors.warningYellow, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        spacing: 14,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 48,
            color: AppColors.deepNavy,
          ),
          Text(
            student.firstName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.deepNavy,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
              decorationThickness: 2,
            ),
          ),
          Text(
            l10n.driverNotRiding.toUpperCase(),
            textAlign: TextAlign.center,
            semanticsLabel: l10n.driverNotRiding,
            style: const TextStyle(
              color: AppColors.deepNavy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          Text(
            l10n.driverNotRidingNote(student.firstName),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
            ),
          ),
          ElevatedButton.icon(
            onPressed: busy
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(
                      () => _acknowledgedAbsent.add(student.attendanceId),
                    );
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              backgroundColor: AppColors.deepNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.skip_next, size: 26),
            label: Text(l10n.driverSkipStop.toUpperCase()),
          ),
          TextButton.icon(
            onPressed: busy
                ? null
                : () => _transition(student, AttendanceService.boardMorning),
            style: TextButton.styleFrom(foregroundColor: AppColors.deepNavy),
            icon: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.directions_bus_filled, size: 20),
            label: Text(l10n.driverBoardAnyway),
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
          borderRadius: BorderRadius.circular(AppRadius.control),
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
