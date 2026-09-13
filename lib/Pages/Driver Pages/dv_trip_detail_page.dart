import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/attendance_status_ui.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_section_header.dart';
import 'package:mockup/services/attendance_service.dart';

import '../../l10n/app_localizations.dart';

/// Full detail for one past run day.
///
/// A day has two independent phases, so the page shows one phase at a time
/// (toggle at the top) and splits that phase's roster into who was present
/// and who was not. A phase that never ran is disabled in the toggle.
class DvTripDetailPage extends StatefulWidget {
  const DvTripDetailPage({
    super.key,
    required this.routeName,
    required this.session,
  });

  final String routeName;
  final TripSession session;

  @override
  State<DvTripDetailPage> createState() => _DvTripDetailPageState();
}

class _DvTripDetailPageState extends State<DvTripDetailPage> {
  late bool _afternoon =
      !widget.session.hasMorning &&
      widget.session.hasAfternoon; // land on a phase that actually ran

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final session = widget.session;

    final recorded = session.recorded(afternoon: _afternoon);
    final present = session.records.where((r) {
      final s = r.statusFor(afternoon: _afternoon);
      return s != null && s != AttendanceStatus.absent;
    }).toList();
    final absent = session.records
        .where(
          (r) => r.statusFor(afternoon: _afternoon) == AttendanceStatus.absent,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripDetails)),
      body: ListView(
        children: [
          _header(context, materialL10n),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.morningRun),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  enabled: session.hasMorning,
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.afternoonRun),
                  icon: const Icon(Icons.home_outlined),
                  enabled: session.hasAfternoon,
                ),
              ],
              selected: {_afternoon},
              onSelectionChanged: (s) => setState(() => _afternoon = s.first),
            ),
          ),
          if (recorded == 0)
            _emptyPhase(l10n)
          else ...[
            _summaryRow(l10n, session),
            if (present.isNotEmpty) ...[
              CmSubsectionHeader(
                '${l10n.present} (${present.length})',
                color: AppColors.deepNavy,
              ),
              for (final r in present) _studentRow(context, r),
            ],
            if (absent.isNotEmpty) ...[
              CmSubsectionHeader(
                '${l10n.statusAbsent} (${absent.length})',
                color: AppColors.dangerRed,
              ),
              for (final r in absent) _studentRow(context, r),
            ],
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, MaterialLocalizations materialL10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            materialL10n.formatFullDate(widget.session.day),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            spacing: 6,
            children: [
              const Icon(
                Icons.directions_bus_filled_outlined,
                color: Colors.grey,
                size: 18,
              ),
              Expanded(
                child: Text(
                  widget.routeName,
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(AppLocalizations l10n, TripSession session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        spacing: 10,
        children: [
          _summaryTile(l10n.summaryTotal, session.total, AppColors.borderGray),
          _summaryTile(
            l10n.present,
            session.present(afternoon: _afternoon),
            AppColors.successTint,
          ),
          _summaryTile(
            l10n.statusAbsent,
            session.absent(afternoon: _afternoon),
            AppColors.dangerTint,
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          spacing: 2,
          children: [
            Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _studentRow(BuildContext context, AttendanceRecord record) {
    final l10n = AppLocalizations.of(context)!;
    final status = record.statusFor(afternoon: _afternoon);
    final isAbsent = status == AttendanceStatus.absent;

    // No interactive children, so merging makes a screen reader announce
    // "<name>, <parent>, <status>" as one stop instead of three.
    return MergeSemantics(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          border: Border.all(color: AppColors.borderGray),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          spacing: 12,
          children: [
            Icon(
              isAbsent ? Icons.person_off_outlined : Icons.child_care,
              size: 24,
              color: isAbsent ? AppColors.dangerRed : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.firstName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (record.parentName.trim().isNotEmpty)
                    Text(
                      '${l10n.parentLabel}: ${record.parentName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                ],
              ),
            ),
            if (status != null)
              Container(
                decoration: BoxDecoration(
                  color: attendanceStatusColor(status),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  attendanceStatusLabel(context, status).toUpperCase(),
                  semanticsLabel: attendanceStatusLabel(context, status),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPhase(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        spacing: 10,
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 44,
            color: AppColors.mutedText,
          ),
          Text(
            l10n.noRunRecorded,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
