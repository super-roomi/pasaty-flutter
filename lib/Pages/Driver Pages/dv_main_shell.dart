import 'package:flutter/material.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_history_page.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_profile_page.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_status_page.dart';

class DvMainShell extends StatefulWidget {
  const DvMainShell({super.key});

  @override
  State<DvMainShell> createState() => _DvMainShellState();
}

class _DvMainShellState extends State<DvMainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    StatusPage(),
    DvHistoryPage(),
    DvProfilePage()
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
            BottomNavigationBarItem(icon: Icon(Icons.directions_bus_filled), label: "Status"),
            BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "History"),
            BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), label: "Profile")
          ],
      ),
      body: _pages[_currentIndex],
    );
  }
}
