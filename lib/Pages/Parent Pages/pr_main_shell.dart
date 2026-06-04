import 'package:flutter/material.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_page.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_payment_page.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_profile_page.dart';

class PrMainShell extends StatefulWidget {
  const PrMainShell({super.key});

  @override
  State<PrMainShell> createState() => _PrMainShellState();
}

class _PrMainShellState extends State<PrMainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    PrMainPage(),
    PrPaymentPage(),
    PrProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Bus Tracker"),
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
            label: "Status",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Payments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: "Profile",
          ),
        ],
      ),
      body: _pages[_currentIndex],
    );
  }
}
