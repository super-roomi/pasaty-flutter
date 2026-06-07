import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/test.dart';

import '../../l10n/app_localizations.dart';

class PrStatusActiveWidget extends StatefulWidget {
  const PrStatusActiveWidget({super.key});

  @override
  State<PrStatusActiveWidget> createState() => _PrStatusActiveWidgetState();
}

class _PrStatusActiveWidgetState extends State<PrStatusActiveWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(20),
            color: Color(0xFF1A2B48),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.currentStatus.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        l10n.arrivingSoon,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  // Container(
                  //   decoration: BoxDecoration(
                  //     border: Border.all(color: Colors.grey),
                  //     borderRadius: BorderRadius.circular(50),
                  //     color: AppColors.warningYellow,
                  //   ),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(6.5),
                  //     child: Text(
                  //       "60-Meter Road",
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ), //Contains Status & Text Location
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.timeLeft.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      Text(
                        l10n.aboutSixMinutesTillArrival,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              //Test(),
            ],
          ),
        ),
      ],
    );
  }
}
