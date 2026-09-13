import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';

import '../../l10n/app_localizations.dart';

/// The status section between runs.
///
/// Previously led with the full app logo, which competed with the header for
/// attention and said nothing about the children. It now states the actual
/// situation — everyone is at home — using the same home icon and tint the
/// roster chips use for that state, so the card and the chips below it agree
/// at a glance.
class PrStatusPagePassive extends StatelessWidget {
  const PrStatusPagePassive({super.key, this.atSchool = false});

  /// Whether the children are at school rather than at home.
  ///
  /// Between runs there are only two resting places, and which one applies
  /// depends on the last run that finished: after the morning run everyone is
  /// at school, after the afternoon one everyone is home. Saying "All home"
  /// while the roster underneath reads "In school" is the contradiction this
  /// flag exists to stop.
  final bool atSchool;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: AppBorders.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: Column(
          spacing: 12,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.neutralTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                atSchool ? Icons.school_outlined : Icons.home_outlined,
                size: 32,
                color: AppColors.deepNavy,
              ),
            ),
            Text(
              atSchool ? l10n.allAtSchool : l10n.allHome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            Text(
              l10n.noActiveTripsMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
