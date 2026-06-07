import 'package:flutter/material.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_status_passive_widget.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_boarding_widget.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_contact_widget.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_status_active_widget.dart';

class PrMainPage extends StatefulWidget {
  const PrMainPage({super.key});

  @override
  State<PrMainPage> createState() => _PrMainPageState();
}

class _PrMainPageState extends State<PrMainPage> {
  String _selectedMode = 'Passive';

  List<Widget> activeSession = [
    PrStatusActiveWidget(),
    PrBoardingWidget(),
    PrContactWidget(),
  ];

  List<Widget> inactiveSession = [PrStatusPagePassive()];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          value: _selectedMode,
          items: const [
            DropdownMenuItem(value: 'Passive', child: Text('Passive')),
            DropdownMenuItem(value: 'Active', child: Text('Active')),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedMode = newValue);
            }
          },
        ),
        Expanded(
          child: _selectedMode == 'Passive'
              ? ListView(children: inactiveSession)
              : ListView(children: activeSession),
        ),
      ],
    );
  }
}
