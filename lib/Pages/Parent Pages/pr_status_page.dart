import 'package:flutter/material.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_boarding_widget.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_contact_widget.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_status_widget.dart';

class PrMainPage extends StatefulWidget {
  const PrMainPage({super.key});

  @override
  State<PrMainPage> createState() => _PrMainPageState();
}

class _PrMainPageState extends State<PrMainPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      PrStatusWidget(),
      PrBoardingWidget(),
      PrContactWidget()
    ],);
  }
}
