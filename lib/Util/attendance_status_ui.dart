import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/services/attendance_service.dart';

import '../l10n/app_localizations.dart';

/// Shared mapping from backend ATTENDANCE_STATUS values to localized
/// labels and chip colors, used by both driver and parent widgets.
String attendanceStatusLabel(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    AttendanceStatus.waiting => l10n.statusWaiting,
    AttendanceStatus.boarded => l10n.statusBoarded,
    AttendanceStatus.arrived => l10n.statusArrived,
    AttendanceStatus.absent => l10n.statusAbsent,
    AttendanceStatus.droppedOff => l10n.statusDroppedOff,
    _ => status,
  };
}

Color attendanceStatusColor(String status) {
  return switch (status) {
    AttendanceStatus.boarded => const Color(0xFFBEFFDC),
    AttendanceStatus.arrived => const Color(0xFFBDE0FF),
    AttendanceStatus.droppedOff => const Color(0xFFBDE0FF),
    AttendanceStatus.absent => AppColors.lightAlertRed,
    _ => const Color(0xFFE9E7EC),
  };
}
