import 'package:flutter/material.dart';
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

    return GestureDetector(
      onTap: () => _confirmLogout(context, l10n),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 14.0),
                  child: Icon(
                    Icons.logout,
                    size: 26,
                    color: AppColors.dangerRed,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.logOut,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dangerRed,
                      ),
                    ),
                    Text(
                      l10n.signOutOfYourAccount,
                      style: const TextStyle(height: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
