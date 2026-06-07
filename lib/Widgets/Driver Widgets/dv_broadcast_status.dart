import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';

import '../../l10n/app_localizations.dart';

class DvBroadcastStatus extends StatelessWidget {
  const DvBroadcastStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),

      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.broadcast_on_home),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  l10n.broadcastUpdates.toUpperCase(),
                  style: TextStyle(letterSpacing: 1.5),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightAlertRed,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    side: BorderSide(color: AppColors.dangerRed, width: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(l10n.majorDelay), Icon(Icons.send_rounded)],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightWarningYellow,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    side: BorderSide(
                      color: AppColors.warningYellow,
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(l10n.minorDelay), Icon(Icons.send_rounded)],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(l10n.onSchedule), Icon(Icons.check_circle)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
