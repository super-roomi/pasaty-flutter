import 'package:flutter/material.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_page.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_profile_page.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_profile_page.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_schedule_page.dart';

class PrMainShell extends StatefulWidget {
  const PrMainShell({super.key});

  @override
  State<PrMainShell> createState() => _PrMainShellState();
}

class _PrMainShellState extends State<PrMainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    PrMainPage(),
    PrSchedulePage(),
    PrProfilePage()
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
        bottomNavigationBar:
        BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => {(setState(() => _currentIndex = index))},
          items:
          [
            BottomNavigationBarItem(icon: Icon(Icons.directions_bus_filled_outlined), label: "Status"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Schedule"),
            BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), label: "Profile")
          ],
        ),
        body: _pages[_currentIndex],
    );
  }
}
