import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/services/attendance_service.dart';

import '../../l10n/app_localizations.dart';

/// What has already happened on this route today.
///
/// The single most useful thing to show a driver on an idle screen is the
/// answer to "have I done the morning run yet?" — a question that otherwise
/// costs a trip into History. Both legs are listed with their counts, so the
/// afternoon is also visible as pending rather than absent.
///
/// Everything here comes from one `attendanceOn(routeId, today)` call, an
/// endpoint the History page already uses. Nothing new is required backend
/// side.
class DvTodayCard extends StatelessWidget {
  const DvTodayCard({super.key, required this.session, required this.loading});

  /// Today's attendance, or null while loading / when nothing is recorded.
  final TripSession? session;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = session;

    final morningRan = s != null && s.recorded(afternoon: false) > 0;
    final afternoonRan = s != null && s.recorded(afternoon: true) > 0;

    // No title row inside the card: the CmSectionHeader above supplies it,
    // matching how the parent roster is labelled.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: AppBorders.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!morningRan && !afternoonRan)
            Text(
              l10n.noRunsToday,
              style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
            )
          else ...[
            _leg(
              context,
              label: l10n.morningRun,
              icon: Icons.wb_sunny_outlined,
              ran: morningRan,
              present: s.present(afternoon: false),
              absent: s.absent(afternoon: false),
            ),
            const SizedBox(height: 8),
            _leg(
              context,
              label: l10n.afternoonRun,
              icon: Icons.home_outlined,
              ran: afternoonRan,
              present: s.present(afternoon: true),
              absent: s.absent(afternoon: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _leg(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool ran,
    required int present,
    required int absent,
  }) {
    final l10n = AppLocalizations.of(context)!;

    // One node per leg: a screen reader says "Morning run, done, 12 present,
    // 1 absent" rather than stopping on each chip.
    return MergeSemantics(
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: ran ? AppColors.deepNavy : AppColors.mutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: ran ? FontWeight.w600 : FontWeight.normal,
                color: ran ? AppColors.deepNavy : AppColors.mutedText,
              ),
            ),
          ),
          if (!ran)
            Text(
              l10n.runPending,
              style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
            )
          else ...[
            _count('$present', l10n.present, AppColors.successTint),
            const SizedBox(width: 6),
            if (absent > 0)
              _count('$absent', l10n.statusAbsent, AppColors.dangerTint),
          ],
        ],
      ),
    );
  }

  Widget _count(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
