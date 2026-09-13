import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Pages/Common/cm_login_page.dart';
import 'package:mockup/Util/error_text.dart';
import 'package:mockup/Util/toast.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_nav_tile.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_section_header.dart';
import 'package:mockup/services/auth_service.dart';
import 'package:mockup/services/protected_service.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';

class PrSettingsPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;

  const PrSettingsPage({super.key, required this.onLocaleChange});

  @override
  State<PrSettingsPage> createState() => _PrSettingsPageState();
}

class _PrSettingsPageState extends State<PrSettingsPage> {
  late Locale _selectedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale = Localizations.localeOf(context); // grab current on init
  }

  String _localeLabel(Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧 ${l10n.englishLanguage}';
      case 'ar':
        return '🇸🇦 ${l10n.arabicLanguage}';
      default:
        return locale.languageCode;
    }
  }

  /// True while the delete request is in flight, so the tile cannot be
  /// double-tapped into two DELETEs.
  bool _deleting = false;

  /// Two-step confirmation for account deletion.
  ///
  /// The dialog is deliberately blunt about permanence, and the destructive
  /// action is not the default — this is the one screen in the app where an
  /// accidental tap cannot be undone.
  Future<void> _confirmDeleteAccount() async {
    if (_deleting) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.selectionClick();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.deleteAccount,
              style: const TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteAccount(l10n);
  }

  /// Deletes the account, then clears the session and returns to login.
  ///
  /// Order matters: the account is gone on the server before anything local
  /// is touched, so a failure leaves the user signed in and able to retry
  /// rather than stranded at a login screen for an account that still exists.
  Future<void> _deleteAccount(AppLocalizations l10n) async {
    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ProtectedService.deleteAccount();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showToastVia(messenger, errorText(context, e), error: true);
      return;
    }

    // The session's tokens now point at a user that no longer exists, so this
    // tears down the socket and wipes storage. The logout call itself failing
    // is expected and harmless — AuthService.logout clears local state in a
    // `finally` regardless.
    await AuthService.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => CmLoginPage(onLocaleChange: widget.onLocaleChange),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          CmSectionHeader(l10n.language),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              border: AppBorders.card,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Column(
              children: L10n.all.map((locale) {
                final isSelected =
                    _selectedLocale.languageCode ==
                    locale.languageCode; // ← fixed
                final isLast = L10n.all.last == locale;

                return Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      title: Text(_localeLabel(locale)),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(
                          () => _selectedLocale = locale,
                        ); // ← update checkmark locally
                        widget.onLocaleChange(
                          locale,
                        ); // ← update app locale globally
                      },
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 16,
                        color: AppColors.borderGray,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          CmSectionHeader(l10n.account),
          CmNavTile(
            icon: Icons.delete_outline,
            title: l10n.deleteAccount,
            subtitle: l10n.deleteAccountDescription,
            destructive: true,
            // A spinner rather than nothing: deletion is a network round trip
            // the user cannot repeat, so silence would invite a second tap.
            trailing: _deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _confirmDeleteAccount,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
