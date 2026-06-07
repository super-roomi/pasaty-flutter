import 'package:flutter/material.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_page.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_payment_page.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_profile_page.dart';

import '../../l10n/app_localizations.dart';

class PrMainShell extends StatefulWidget {
  const PrMainShell({super.key, required this.onLocaleChange});
  final void Function(Locale) onLocaleChange;

  @override
  State<PrMainShell> createState() => _PrMainShellState();
}

class _PrMainShellState extends State<PrMainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = [
      PrMainPage(),
      PrPaymentPage(),
      PrProfilePage(onLocaleChange: widget.onLocaleChange),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.appTitle,
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.notifications_none_outlined),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // selectedItemColor: AppColors.deepNavy,
        // unselectedItemColor: AppColors.deepNavy,
        currentIndex: _currentIndex,
        onTap: (index) => {(setState(() => _currentIndex = index))},
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_filled_outlined),
            label: l10n.status,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: l10n.payments,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: l10n.profile,
          ),
        ],
      ),
      body: pages[_currentIndex],
    );
  }
}
