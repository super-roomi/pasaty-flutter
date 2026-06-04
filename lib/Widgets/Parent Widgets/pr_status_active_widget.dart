import 'package:flutter/material.dart';
import 'package:mockup/Colors/AppColors.dart';
import 'package:mockup/test.dart';

class PrStatusActiveWidget extends StatefulWidget {
  const PrStatusActiveWidget({super.key});

  @override
  State<PrStatusActiveWidget> createState() => _PrStatusActiveWidgetState();
}

class _PrStatusActiveWidgetState extends State<PrStatusActiveWidget> {
  @override
  Widget build(BuildContext context) {
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
                        "CURRENT STATUS",
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "Arriving Soon",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
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
                        "TIME LEFT",
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      Text(
                        "About 6mins till arrival",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Test()
            ],
          ),
        ),
      ],
    );
  }
}
