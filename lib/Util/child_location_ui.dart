import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/services/attendance_service.dart';

import '../l10n/app_localizations.dart';

/// Where a child physically is, as a parent thinks about it.
///
/// The backend tracks a per-phase attendance state machine (WAITING ->
/// BOARDED -> ARRIVED / DROPPED_OFF / ABSENT). Parents do not care about the
/// state machine; they care about one question. The same raw status means a
/// different place depending on the phase, which is why [childLocationFor]
/// needs both.
enum ChildLocation { atHome, onBus, inSchool }

/// Maps a phase + attendance status onto a physical location.
///
///  morning   WAITING     -> not collected yet          -> at home
///            BOARDED     -> collected                  -> on bus
///            ARRIVED     -> delivered to school        -> in school
///            ABSENT      -> never collected            -> at home
///  afternoon WAITING     -> waiting for the ride home  -> in school
///            BOARDED     -> on the way home            -> on bus
///            DROPPED_OFF -> delivered home             -> at home
///            ABSENT      -> did not take the bus home  -> at home
///
/// Returns null when the status is unknown, so callers can fall back to a
/// neutral "no information yet" presentation rather than guessing.
ChildLocation? childLocationFor({
  required String? phase,
  required String? status,
}) {
  if (status == null) return null;
  final afternoon = phase == 'afternoon';

  return switch (status) {
    AttendanceStatus.boarded => ChildLocation.onBus,
    AttendanceStatus.arrived => ChildLocation.inSchool,
    AttendanceStatus.droppedOff => ChildLocation.atHome,
    AttendanceStatus.absent => ChildLocation.atHome,
    AttendanceStatus.waiting =>
      afternoon ? ChildLocation.inSchool : ChildLocation.atHome,
    _ => null,
  };
}

String childLocationLabel(BuildContext context, ChildLocation location) {
  final l10n = AppLocalizations.of(context)!;
  return switch (location) {
    ChildLocation.atHome => l10n.atHome,
    ChildLocation.onBus => l10n.onBus,
    ChildLocation.inSchool => l10n.inSchool,
  };
}

Color childLocationColor(ChildLocation location) {
  return switch (location) {
    ChildLocation.onBus => AppColors.successTint,
    ChildLocation.inSchool => AppColors.infoTint,
    ChildLocation.atHome => AppColors.neutralTint,
  };
}

IconData childLocationIcon(ChildLocation location) {
  return switch (location) {
    ChildLocation.onBus => Icons.directions_bus_filled,
    ChildLocation.inSchool => Icons.school,
    ChildLocation.atHome => Icons.home,
  };
}
