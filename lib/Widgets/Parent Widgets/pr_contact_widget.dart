import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/open_whatsapp.dart';
import 'package:mockup/Util/toast.dart';

import '../../l10n/app_localizations.dart';

/// Support contact card.
///
/// Shown on the parent's home screen only while a trip is under way, and
/// permanently on the profile page so there is always a way to reach support
/// between runs.
///
/// This used to dial a hardcoded personal mobile number and was labelled
/// "Call Samer", so every parent was given one specific person regardless of
/// which bus their child rode. It now opens a WhatsApp chat with the support
/// number instead.
class PrContactWidget extends StatelessWidget {
  const PrContactWidget({super.key});

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.selectionClick();

    var opened = false;
    try {
      opened = await openSupportWhatsApp();
    } catch (_) {
      opened = false;
    }
    // Failing silently would look like a dead button.
    if (!opened) {
      showToastVia(messenger, l10n.couldNotOpenWhatsapp, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warningTint,
          border: AppBorders.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              l10n.contactUs,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              l10n.contactUsDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _open(context),
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: Text(
                  l10n.contactViaWhatsapp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
