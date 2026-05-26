import 'package:flutter/material.dart';

class PrPaymentPage extends StatelessWidget {
  const PrPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Image.asset(
                          "assets/images/qi-card-seeklogo.png",
                        ),
                      ),
                    ],
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                      child: Row(
                        spacing: 10,
                        children: [
                          Text("Pay your bus fees with Qi", style: TextStyle(fontSize: 18),),
                          Icon(Icons.arrow_forward_ios, size: 18,)
                        ],
                      ))
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
