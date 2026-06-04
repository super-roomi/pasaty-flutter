import 'package:flutter/material.dart';

class PrStatusPagePassive extends StatelessWidget {
  const PrStatusPagePassive({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(child: Image.asset("assets/images/logo.png")),
        Center(
          child: Column(
            children: [
              Text(
                "No Active Trips",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 300,
                child: Text(
                  "The bus is currently resting at the depot. We'll notify you as soon as the next route begins.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
