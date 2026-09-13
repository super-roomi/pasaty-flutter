import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/attendance_status_ui.dart';
import 'package:mockup/services/attendance_service.dart';

import '../../l10n/app_localizations.dart';

/// One student row on the attendance page.
///
/// Fast-path UX instead of two flat buttons: tapping anywhere on the card
/// boards the student (the common case), swiping start-to-end boards,
/// swiping end-to-start marks absent. Both states stay correctable — the
/// trailing round toggles flip a student between boarded and absent, and
/// the card color animates with the status.
class DvStudentCard extends StatelessWidget {
  final AttendanceStudent student;
  final bool busy;
  final VoidCallback onBoard;
  final VoidCallback onAbsent;

  const DvStudentCard({
    super.key,
    required this.student,
    required this.busy,
    required this.onBoard,
    required this.onAbsent,
  });

  static const _boardedFill = AppColors.successTint;
  static const _boardedEdge = AppColors.successGreen;
  static const _absentFill = AppColors.dangerTint;
  static const _waitingFill = AppColors.surfaceMuted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = student.status;
    final boarded = status == AttendanceStatus.boarded;
    final absent = status == AttendanceStatus.absent;

    return Dismissible(
      key: ValueKey('attendance-${student.attendanceId}'),
      // Swipes trigger the transition but never remove the card.
      confirmDismiss: (direction) async {
        if (busy) return false;
        if (direction == DismissDirection.startToEnd) {
          if (!boarded) onBoard();
        } else {
          if (!absent) onAbsent();
        }
        return false;
      },
      background: _swipeBackground(
        alignment: AlignmentDirectional.centerStart,
        color: _boardedEdge,
        icon: Icons.directions_bus_filled,
        label: l10n.board,
      ),
      secondaryBackground: _swipeBackground(
        alignment: AlignmentDirectional.centerEnd,
        color: AppColors.dangerRed,
        icon: Icons.person_off_outlined,
        label: l10n.absent,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: busy || boarded ? null : onBoard,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: boarded
                    ? _boardedFill
                    : absent
                    ? _absentFill
                    : _waitingFill,
                border: Border.all(
                  color: boarded
                      ? _boardedEdge
                      : absent
                      ? AppColors.dangerRed
                      : AppColors.borderGray,
                ),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Icon(
                      absent ? Icons.person_off_outlined : Icons.child_care,
                      size: 26,
                      color: absent ? AppColors.dangerRed : null,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.firstName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            attendanceStatusLabel(context, status),
                            key: ValueKey(status),
                            style: TextStyle(
                              fontSize: 13,
                              color: boarded
                                  ? _boardedEdge
                                  : absent
                                  ? AppColors.dangerRed
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    _statusToggle(
                      active: boarded,
                      color: _boardedEdge,
                      icon: Icons.check,
                      label: l10n.board,
                      onTap: boarded ? null : onBoard,
                    ),
                    const SizedBox(width: 8),
                    _statusToggle(
                      active: absent,
                      color: AppColors.dangerRed,
                      icon: Icons.person_off_outlined,
                      label: l10n.absent,
                      onTap: absent ? null : onAbsent,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Round check / absent toggle that fills with its color when active.
  ///
  /// 48x48 to clear the WCAG/Material minimum touch target — the visible
  /// circle is smaller (42dp) so the extra tap area is invisible padding,
  /// not a bigger button.
  Widget _statusToggle({
    required bool active,
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      selected: active,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color : Colors.transparent,
              border: Border.all(
                color: active ? color : Colors.grey,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: active ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(icon, color: Colors.white),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
