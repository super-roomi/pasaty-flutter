import 'package:flutter/material.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_page.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_profile_page.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_main_shell.dart';

import '../../l10n/app_localizations.dart';

/// Signed-in chrome for a parent. All the behaviour lives in [CmMainShell];
/// this only names the tabs.
class PrMainShell extends StatelessWidget {
  const PrMainShell({super.key, required this.onLocaleChange});
  final void Function(Locale) onLocaleChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CmMainShell(
      tabs: [
        CmShellTab(
          icon: Icons.directions_bus_filled_outlined,
          label: l10n.status,
          builder: (_) => const PrMainPage(),
        ),
        CmShellTab(
          icon: Icons.person_2_outlined,
          label: l10n.profile,
          title: l10n.profile,
          builder: (_) => PrProfilePage(onLocaleChange: onLocaleChange),
        ),
      ],
    );
  }
}
