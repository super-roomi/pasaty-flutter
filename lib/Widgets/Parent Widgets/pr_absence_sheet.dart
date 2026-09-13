import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/error_text.dart';
import 'package:mockup/Util/toast.dart';
import 'package:mockup/services/absence_service.dart';
import 'package:mockup/services/api_client.dart';

import '../../l10n/app_localizations.dart';

/// Everything a parent can do about one child riding the bus, in one sheet.
///
/// Opened from the child's row on the status page.
///
/// The sheet never guesses which morning the parent means. It offers the next
/// several mornings by name and date and lets them pick, because "today" is
/// only the right default for part of the day: a parent acting at eight in the
/// morning means this morning, and one acting after school means tomorrow. An
/// earlier version had a single "Not riding today" button, which read as
/// nonsense in the afternoon — and, on a route that had not run that day, the
/// server would accept the booking for a morning that had already passed and
/// answer success, so the parent was told it worked and nothing happened.
///
/// Every day shown is counted from the *server's* today
/// ([AbsenceWindow.today]), never the device's. Longer spans still go through
/// the range picker.
class PrAbsenceSheet extends StatefulWidget {
  const PrAbsenceSheet({
    super.key,
    required this.studentId,
    required this.studentName,
    this.morningOver = false,
  });

  final int studentId;
  final String studentName;

  /// Whether this morning's run has already been and gone for this child.
  ///
  /// Known from the child's own attendance: once the morning status has landed
  /// on arrived or absent, that run is finished. Used to strike out today and
  /// move the default to tomorrow — the server would otherwise refuse it, or
  /// worse, accept a booking that can no longer change anything.
  final bool morningOver;

  /// Opens the sheet.
  ///
  /// [AbsenceOutcome.changed] says whether the booked list moved, so the
  /// caller can reload it. [AbsenceOutcome.statusChanged] is narrower: it is
  /// only true when the server applied a declaration to a run that was already
  /// out, which is the one case where the child's live attendance status can
  /// have moved too. A future-dated booking changes nothing today, and
  /// re-fetching attendance for it just fires a 404 per child.
  static Future<AbsenceOutcome> show(
    BuildContext context, {
    required int studentId,
    required String studentName,
    bool morningOver = false,
  }) async {
    final outcome = await showModalBottomSheet<AbsenceOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (_) => PrAbsenceSheet(
        studentId: studentId,
        studentName: studentName,
        morningOver: morningOver,
      ),
    );
    return outcome ?? const AbsenceOutcome();
  }

  @override
  State<PrAbsenceSheet> createState() => _PrAbsenceSheetState();
}

class _PrAbsenceSheetState extends State<PrAbsenceSheet> {
  /// How many mornings to offer as one-tap choices. A week covers "he is off
  /// sick until Friday" without turning the sheet into a calendar; anything
  /// longer goes through the range picker.
  static const int _quickDays = 7;

  /// The school's calendar day, from the server. Null until loaded.
  String? _today;

  /// Booked dates for this child.
  Set<String> _booked = const {};

  String? _loadError;
  bool _loading = true;
  bool _working = false;

  bool _changed = false;
  bool _statusChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final window = await AbsenceService.upcoming();
      if (!mounted) return;
      setState(() {
        _today = window.today.isEmpty ? null : window.today;
        _booked = {
          for (final a in window.absences)
            if (a.studentId == widget.studentId) a.date,
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = errorText(context, e);
      });
    }
  }

  /// The mornings offered as one-tap choices, earliest first.
  List<String> get _days {
    final today = _today;
    if (today == null) return const [];
    return [
      for (var i = 0; i < _quickDays; i++) AbsenceWindow.addDays(today, i),
    ];
  }

  /// Whether a day can still be acted on. Today drops out once its run is
  /// done — booking it would change nothing.
  bool _selectable(String date) => !(date == _today && widget.morningOver);

  // ------------------------------------------------------------------ acting

  Future<void> _toggle(String date) async {
    if (_booked.contains(date)) {
      await _cancel(date);
      return;
    }
    await _declare(date);
  }

  Future<void> _declare(String date) async {
    final l10n = AppLocalizations.of(context)!;
    final label = _dayLabel(context, date, long: true);

    // Always confirmed: this stops a bus.
    final confirmed = await _confirm(
      title: l10n.absenceConfirmTitle,
      message: l10n.absenceConfirmDayMessage(widget.studentName, label),
      action: l10n.absenceConfirmAction,
    );
    if (confirmed != true) return;

    await _send(
      // Today is declared by omitting the date, so the server resolves its own
      // calendar day rather than trusting one computed here.
      date == _today
          ? () => AbsenceService.declareToday(widget.studentId)
          : () => AbsenceService.declareDays(
              studentId: widget.studentId,
              from: date,
              to: date,
            ),
      label: label,
    );
  }

  Future<void> _declareRange() async {
    final l10n = AppLocalizations.of(context)!;
    final today = _today;
    if (today == null) return;

    // Anchored on the server's today so the picker cannot offer a day the
    // server would reject as past.
    final first = _parse(today) ?? DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: first.add(const Duration(days: AbsenceService.maxRangeDays)),
      helpText: l10n.planAhead,
      saveText: l10n.absencePickDays,
    );
    if (picked == null || !mounted) return;

    final span = picked.end.difference(picked.start).inDays + 1;
    if (span > AbsenceService.maxRangeDays) {
      _toast(l10n.absenceRangeTooLong(AbsenceService.maxRangeDays));
      return;
    }

    final confirmed = await _confirm(
      title: l10n.absenceRangeConfirmTitle,
      message: l10n.absenceRangeConfirmMessage(widget.studentName),
      action: l10n.absenceConfirmAction,
    );
    if (confirmed != true) return;

    await _send(
      () => AbsenceService.declareRange(
        studentId: widget.studentId,
        from: picked.start,
        to: picked.end,
      ),
    );
  }

  /// Runs a declare call and turns its per-day answer into one message.
  Future<void> _send(
    Future<AbsenceResult> Function() call, {
    String? label,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _working = true);
    try {
      final result = await call();
      if (!mounted) return;

      if (result.booked.isNotEmpty) {
        _changed = true;
        if (result.anyLive) _statusChanged = true;
        HapticFeedback.mediumImpact();
      }

      // A partly-honoured range is the interesting case: say what got booked
      // and why the rest did not, rather than a bare success or failure.
      final refused = result.refused;
      if (result.booked.isEmpty && refused.isNotEmpty) {
        _toast(_refusalText(l10n, refused.first.reason), error: true);
      } else if (refused.isNotEmpty) {
        _toast(
          '${l10n.absencePartlyBooked(result.booked.length, result.days.length)}'
          ' ${_refusalText(l10n, refused.first.reason)}',
        );
      } else if (result.anyLive) {
        _toast(l10n.absenceBookedLive);
      } else if (label != null) {
        _toast(l10n.absenceBookedOn(widget.studentName, label));
      } else {
        _toast(l10n.absenceBooked(widget.studentName));
      }

      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 means no day could be honoured at all. The server's own prose is
      // English-only, so the wording comes from the ARB files instead.
      _toast(
        e.kind == ApiErrorKind.conflict
            ? l10n.absenceAlreadyBoarded(widget.studentName)
            : errorText(context, e),
        error: true,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(errorText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _cancel(String date) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _working = true);
    try {
      await AbsenceService.cancel(studentId: widget.studentId, date: date);
      if (!mounted) return;
      _changed = true;
      _statusChanged = true;
      HapticFeedback.selectionClick();
      _toast(l10n.absenceCancelled(widget.studentName));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 here is specific and actionable: the run has started, so putting
      // the child back on it is the driver's call.
      _toast(
        e.kind == ApiErrorKind.conflict
            ? l10n.absenceRunStarted
            : errorText(context, e),
        error: true,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(errorText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _refusalText(AppLocalizations l10n, String? reason) {
    return switch (reason) {
      AbsenceRefusal.alreadyBoarded => l10n.absenceAlreadyBoarded(
        widget.studentName,
      ),
      _ => l10n.absenceRunFinished,
    };
  }

  // ------------------------------------------------------------------ chrome

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    showToast(context, message, error: error);
  }

  /// A `YYYY-MM-DD` label split by hand.
  ///
  /// Never [DateTime.parse]: these are school-timezone calendar labels, and
  /// re-reading one in the device's zone can shift it by a day.
  DateTime? _parse(String date) {
    final parts = date.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return null;
    // Noon, so nothing downstream can tip the day over a boundary.
    return DateTime(parts[0]!, parts[1]!, parts[2]!, 12);
  }

  /// "This morning", "Tomorrow", otherwise a weekday and date.
  String _dayLabel(BuildContext context, String date, {bool long = false}) {
    final l10n = AppLocalizations.of(context)!;
    final today = _today;
    if (today != null && !long) {
      if (date == today) return l10n.absenceDayToday;
      if (date == AbsenceWindow.addDays(today, 1)) return l10n.absenceDayTomorrow;
    }
    final parsed = _parse(date);
    if (parsed == null) return date;
    return MaterialLocalizations.of(context).formatMediumDate(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            Navigator.pop(
              context,
              AbsenceOutcome(
                changed: _changed,
                statusChanged: _statusChanged,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.studentName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.absenceMorningOnly(widget.studentName),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.absencePickMorning.toUpperCase(),
                semanticsLabel: l10n.absencePickMorning,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: _body(l10n)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _working || _loading ? null : _declareRange,
                icon: const Icon(Icons.date_range, size: 20),
                label: Text(l10n.planAhead),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final error = _loadError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.dangerRed,
                ),
              ),
            ),
            TextButton(onPressed: _load, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    final days = _days;
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: days.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _dayRow(l10n, days[index]),
    );
  }

  Widget _dayRow(AppLocalizations l10n, String date) {
    final booked = _booked.contains(date);
    final selectable = _selectable(date);
    final label = _dayLabel(context, date);
    final subtitle = date == _today && widget.morningOver
        ? l10n.absenceTodayPassed
        : null;

    return Semantics(
      button: selectable,
      enabled: selectable,
      toggled: booked,
      label: '$label. ${booked ? l10n.absenceBookedLabel : l10n.notRidingToday}',
      excludeSemantics: true,
      child: Material(
        color: booked ? AppColors.warningTint : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: !selectable || _working ? null : () => _toggle(date),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: booked ? AppColors.warningYellow : AppColors.borderGray,
              ),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              spacing: 12,
              children: [
                Icon(
                  booked ? Icons.event_busy : Icons.directions_bus_filled,
                  size: 20,
                  color: selectable ? null : AppColors.mutedText,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: booked
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selectable ? null : AppColors.mutedText,
                          decoration: selectable
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
                if (booked)
                  Text(
                    l10n.absenceUndo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What a visit to [PrAbsenceSheet] actually altered.
class AbsenceOutcome {
  /// The booked-days list moved, so the roster's badges are stale.
  final bool changed;

  /// The child's live attendance status may have moved too — only possible
  /// when a run was already under way.
  final bool statusChanged;

  const AbsenceOutcome({this.changed = false, this.statusChanged = false});
}
