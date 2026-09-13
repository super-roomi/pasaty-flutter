import 'package:flutter/material.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_boarding_widget.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_contact_widget.dart';

/// Parent home.
///
/// The boarding roster is always shown. [PrBoardingWidget] owns the page's
/// single scroll view (so pull-to-refresh covers everything) and renders the
/// contact card after the roster. When no run has started today it puts the
/// passive banner above the roster rather than replacing it.
///
/// This replaced a manual Passive/Active dropdown that hid live status behind
/// a control most parents never touched, and an "arriving soon / about 6 mins"
/// card whose values were hardcoded rather than derived from the trip.
class PrMainPage extends StatelessWidget {
  const PrMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrBoardingWidget(trailing: PrContactWidget());
  }
}
