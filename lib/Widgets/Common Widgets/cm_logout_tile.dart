import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Pages/Common/cm_login_page.dart';
import 'package:mockup/services/auth_service.dart';

import '../../l10n/app_localizations.dart';

/// Logout entry for the profile pages, styled to match the settings tile.
/// Asks for confirmation, revokes the session on the backend, and returns
/// to the login screen.
class CmLogoutTile extends StatelessWidget {
  const CmLogoutTile({super.key, required this.onLocaleChange});
  final void Function(Locale) onLocaleChange;

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await AuthService.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => CmLoginPage(onLocaleChange: onLocaleChange),
      ),
      (route) => false,
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.endSessionDialogTitle),
        content: Text(l10n.logOutDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(dialogContext);
              _logout(context);
            },
            child: Text(
              l10n.logOut,
              style: const TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // InkWell, not GestureDetector: gives a press ripple and, just as
    // importantly, reports itself as a button to screen readers.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmLogout(context, l10n),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Semantics(
            button: true,
            label: '${l10n.logOut}. ${l10n.signOutOfYourAccount}',
            excludeSemantics: true,
            child: Container(
              decoration: BoxDecoration(
                border: AppBorders.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 18.0,
                ),
                // `spacing` follows the reading direction; the previous
                // EdgeInsets.only(right:) put the gap on the wrong side in
                // Arabic and jammed the icon against the label.
                child: Row(
                  spacing: 14,
                  children: [
                    const Icon(
                      Icons.logout,
                      size: 26,
                      color: AppColors.dangerRed,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            l10n.logOut,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dangerRed,
                            ),
                          ),
                          Text(
                            l10n.signOutOfYourAccount,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
