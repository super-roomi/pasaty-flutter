import 'package:flutter/material.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_history_page.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_profile_page.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_status_page.dart';

import '../../l10n/app_localizations.dart';

class DvMainShell extends StatefulWidget {
  const DvMainShell({super.key, required this.onLocaleChange});
  final void Function(Locale) onLocaleChange;

  @override
  State<DvMainShell> createState() => _DvMainShellState();
}

class _DvMainShellState extends State<DvMainShell> {
  int _currentIndex = 0;

  // Built once and shown through an IndexedStack so tab switches keep each
  // page's state alive — an active run on StatusPage must survive visiting
  // History or Profile.
  late final List<Widget> _pages = [
    const StatusPage(),
    const DvHistoryPage(),
    DvProfilePage(onLocaleChange: widget.onLocaleChange),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.appTitle),
            Icon(Icons.notifications_none_outlined),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => {(setState(() => _currentIndex = index))},
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_filled),
            label: l10n.status,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: l10n.history,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: l10n.profile,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
    );
  }
}
