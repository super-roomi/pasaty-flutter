import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_settings_page.dart';
import 'package:mockup/Util/open_privacy_policy.dart';
import 'package:mockup/Util/toast.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_logout_tile.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_nav_tile.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_section_header.dart';

import '../../l10n/app_localizations.dart';

/// The profile screen shared by both roles.
///
/// Driver and parent profiles were separate files that had drifted into near
/// duplicates: the same identity card, settings tile, privacy tile and logout
/// tile, differing only in which icon sits on the avatar and which two values
/// fill the card. Only those values are parameters now; the layout has one
/// home.
///
/// Loading stays with the caller, because the two roles read different
/// endpoints (`/students` vs `/myroutes`) — this widget is presentation only.
class CmProfilePage extends StatefulWidget {
  const CmProfilePage({
    super.key,
    required this.name,
    required this.avatarIcon,
    required this.metaIcon,
    required this.metaText,
    required this.detailLabel,
    required this.detailValue,
    required this.onLocaleChange,
    this.trailing = const [],
  });

  /// Display name, already resolved against the cached session by the caller.
  final String name;

  final IconData avatarIcon;

  /// The secondary line beside the name — the school, for both roles.
  final IconData metaIcon;
  final String metaText;

  /// The row under the hairline: a label and its value.
  final String detailLabel;
  final String detailValue;

  final void Function(Locale) onLocaleChange;

  /// Appended after the logout tile. The parent puts the support card here.
  final List<Widget> trailing;

  @override
  State<CmProfilePage> createState() => _CmProfilePageState();
}

class _CmProfilePageState extends State<CmProfilePage> {
  /// Opens the policy in the browser, telling the user if nothing on the
  /// device can handle the link rather than leaving the tap looking dead.
  Future<void> _openPrivacyPolicy(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final opened = await openPrivacyPolicy(languageCode);
    if (!opened && mounted) {
      showToastVia(messenger, l10n.couldNotOpenLink, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          CmSectionHeader(l10n.account),

          // Identity and assignment are one topic, so they live in a single
          // bounded card split by a hairline, rather than a bordered card
          // followed by a loud yellow tile.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: AppBorders.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      spacing: 16,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.deepNavy,
                          child: Icon(
                            widget.avatarIcon,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 6,
                            children: [
                              Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              _metaRow(widget.metaIcon, widget.metaText),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderGray),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      spacing: 12,
                      children: [
                        const Icon(
                          Icons.directions_bus_filled_outlined,
                          size: 22,
                          color: AppColors.mutedText,
                        ),
                        Expanded(
                          child: Text(
                            widget.detailLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                        Text(
                          widget.detailValue,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          CmSectionHeader(l10n.settings),
          CmNavTile(
            icon: Icons.settings_outlined,
            title: l10n.settings,
            subtitle: l10n.managePersonalInformation,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PrSettingsPage(onLocaleChange: widget.onLocaleChange),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CmNavTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            subtitle: l10n.privacyPolicyDescription,
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openPrivacyPolicy(l10n),
          ),
          CmLogoutTile(onLocaleChange: widget.onLocaleChange),
          ...widget.trailing,
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      spacing: 8,
      children: [
        Icon(icon, size: 17, color: AppColors.mutedText),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
        ),
      ],
    );
  }
}
