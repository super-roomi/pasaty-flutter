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
          // child:
      ),
    );
  }
}
