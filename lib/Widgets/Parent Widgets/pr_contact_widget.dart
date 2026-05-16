import 'package:flutter/material.dart';

import '../../Colors/AppColors.dart';

class PrContactWidget extends StatelessWidget {
  const PrContactWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderGray),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            spacing: 2,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Contact Driver", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Worried about delays? Checking on Rima and Mohammed?"),
              ElevatedButton.icon(
                onPressed: () {},
                label: Text("Call Samer"),
                icon: Icon(Icons.call),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
