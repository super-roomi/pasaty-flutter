import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_trip_detail_page.dart';
import 'package:mockup/Util/calendar_date.dart';
import 'package:mockup/Util/error_text.dart';
import 'package:mockup/Util/toast.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_state_view.dart';
import 'package:mockup/services/attendance_service.dart';
import 'package:mockup/services/protected_service.dart';

import '../../l10n/app_localizations.dart';

/// Driver history: past run days for a route, newest first.
///
/// The backend exposes attendance one date at a time (no "list sessions"
/// endpoint), so this walks back a window of days and keeps the ones that
/// have a recorded run. "Pick a date" jumps straight to any single day
/// without scanning.
class DvHistoryPage extends StatefulWidget {
  const DvHistoryPage({super.key});

  @override
  State<DvHistoryPage> createState() => _DvHistoryPageState();
}

class _DvHistoryPageState extends State<DvHistoryPage> {
  /// Days pulled per fetch. Each day costs one request, so keep it modest
  /// and let the driver ask for more.
  static const _windowDays = 14;

  List<DriverRoute>? _routes;
  DriverRoute? _selectedRoute;

  final List<TripSession> _sessions = [];
  int _daysScanned = 0;

  bool _loading = false;
  String? _error;

  /// Days in the scanned window whose request failed while others succeeded.
  ///
  /// Such a day is dropped, and a dropped day looks exactly like a day with no
  /// run — so without this the list quietly reads as complete when it is not.
  int _unreadableDays = 0;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _routes = null;
      _error = null;
    });
    try {
      final routes = await ProtectedService.getMyRoutes();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _selectedRoute = routes.isNotEmpty ? routes.first : null;
      });
      if (_selectedRoute != null) await _loadMore(reset: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routes = const [];
        _error = errorText(context, e);
      });
    }
  }

  Future<void> _loadMore({bool reset = false}) async {
    final route = _selectedRoute;
    if (route == null || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _sessions.clear();
        _daysScanned = 0;
        _unreadableDays = 0;
      }
    });

    final today = DateTime.now();
    final endDay = DateTime(today.year, today.month, today.day - _daysScanned);

    try {
      final found = await AttendanceService.loadSessions(
        route.id,
        endDay: endDay,
        days: _windowDays,
      );
      if (!mounted) return;
      setState(() {
        _sessions.addAll(found.sessions);
        _daysScanned += _windowDays;
        _unreadableDays += found.unreadableDays;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final route = _selectedRoute;
    if (route == null) return;

    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
    );
    if (picked == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final records = await AttendanceService.attendanceOn(route.id, picked);
      if (!mounted) return;
      if (records.isEmpty) {
        _snack(l10n.noTripOnDate);
        return;
      }
      final session = TripSession(
        date: formatCalendarDate(picked),
        day: DateTime(picked.year, picked.month, picked.day),
        records: records,
      );
      _openDetail(session);
    } catch (e) {
      if (mounted) _snack(errorText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(TripSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DvTripDetailPage(
          routeName: _selectedRoute?.name ?? '',
          session: session,
        ),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    showToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final routes = _routes;

    if (routes == null) {
      return CmSkeleton.historyPage();
    }

    if (routes.isEmpty) {
      return _error != null
          ? CmStateView.error(
              message: _error!,
              actionLabel: l10n.retry,
              onAction: _loadRoutes,
            )
          : CmStateView.empty(
              icon: Icons.directions_bus_filled_outlined,
              message: l10n.noRoutesAssigned,
              actionLabel: l10n.retry,
              onAction: _loadRoutes,
            );
    }

    return Column(
      children: [
        _toolbar(l10n, routes),
        Expanded(child: _body(l10n)),
      ],
    );
  }

  Widget _toolbar(AppLocalizations l10n, List<DriverRoute> routes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            l10n.pastTrips,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (routes.length > 1)
            DropdownButton<DriverRoute>(
              value: _selectedRoute,
              isExpanded: true,
              items: [
                for (final r in routes)
                  DropdownMenuItem(value: r, child: Text(r.name)),
              ],
              onChanged: _loading
                  ? null
                  : (r) {
                      setState(() => _selectedRoute = r);
                      _loadMore(reset: true);
                    },
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _pickDate,
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              label: Text(l10n.pickDate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_sessions.isEmpty) {
      if (_loading) {
        return CmSkeleton.tripList();
      }
      return _error != null
          ? CmStateView.error(
              message: _error!,
              actionLabel: l10n.retry,
              onAction: () => _loadMore(reset: true),
            )
          : CmStateView.empty(
              icon: Icons.history,
              message: l10n.noPastTrips,
              actionLabel: l10n.loadEarlier,
              onAction: _loadMore,
            );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      itemCount: _sessions.length + 1,
      itemBuilder: (context, index) {
        if (index == _sessions.length) return _footer(l10n);
        return _sessionCard(context, _sessions[index]);
      },
    );
  }

  Widget _footer(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        spacing: 8,
        children: [
          if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.dangerRed),
            ),
          // Not an error — the days that did load are real. It says the list
          // has holes, so an absent day is not read as "no run that day".
          if (_unreadableDays > 0)
            Text(
              l10n.historyIncomplete(_unreadableDays),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedText,
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more, size: 20),
                label: Text(l10n.loadEarlier),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sessionCard(BuildContext context, TripSession session) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: () => _openDetail(session),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        materialL10n.formatMediumDate(session.day),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _phaseLine(
                        l10n,
                        session,
                        afternoon: false,
                        icon: Icons.wb_sunny_outlined,
                      ),
                      _phaseLine(
                        l10n,
                        session,
                        afternoon: true,
                        icon: Icons.home_outlined,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phaseLine(
    AppLocalizations l10n,
    TripSession session, {
    required bool afternoon,
    required IconData icon,
  }) {
    final label = afternoon ? l10n.afternoonRun : l10n.morningRun;
    final ran = session.recorded(afternoon: afternoon) > 0;

    // Wrap, not Row: the label plus two count chips can exceed a narrow
    // screen's width, and the Arabic labels are a different length again.
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText),
        Text('$label:', style: const TextStyle(fontSize: 13)),
        if (!ran)
          Text(
            l10n.noRunRecorded,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          )
        else ...[
          _countChip(
            '${session.present(afternoon: afternoon)}',
            l10n.present,
            AppColors.successTint,
          ),
          _countChip(
            '${session.absent(afternoon: afternoon)}',
            l10n.statusAbsent,
            AppColors.dangerTint,
          ),
        ],
      ],
    );
  }

  Widget _countChip(String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text('$value $label', style: const TextStyle(fontSize: 12)),
    );
  }
}
