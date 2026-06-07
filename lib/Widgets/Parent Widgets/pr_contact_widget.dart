import 'package:flutter/material.dart';
import 'package:mockup/Util/make_phone_call.dart';

import '../../Colors/app_colors.dart';
import '../../l10n/app_localizations.dart';

class PrContactWidget extends StatelessWidget {
  const PrContactWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderGray),
            borderRadius: BorderRadius.circular(20),
            color: Color(0xFFFFEFD4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              spacing: 2,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.contactDriver,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(l10n.contactDriverDescription),
                ElevatedButton.icon(
                  onPressed: () {
                    makePhoneCall();
                  },
                  label: Text(l10n.callSamer),
                  icon: Icon(Icons.call),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
