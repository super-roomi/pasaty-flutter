import 'package:flutter/material.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_history_page.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_profile_page.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_status_page.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_main_shell.dart';

import '../../l10n/app_localizations.dart';

/// Signed-in chrome for a driver. All the behaviour lives in [CmMainShell];
/// this only names the tabs.
class DvMainShell extends StatelessWidget {
  const DvMainShell({super.key, required this.onLocaleChange});
  final void Function(Locale) onLocaleChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CmMainShell(
      tabs: [
        CmShellTab(
          icon: Icons.directions_bus_filled,
          label: l10n.status,
          builder: (_) => const StatusPage(),
        ),
        CmShellTab(
          icon: Icons.show_chart,
          label: l10n.history,
          title: l10n.history,
          builder: (_) => const DvHistoryPage(),
        ),
        CmShellTab(
          icon: Icons.person_2_outlined,
          label: l10n.profile,
          title: l10n.profile,
          builder: (_) => DvProfilePage(onLocaleChange: onLocaleChange),
        ),
      ],
    );
  }
}
