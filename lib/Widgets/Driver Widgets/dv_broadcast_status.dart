import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';

import '../../l10n/app_localizations.dart';

/// Whether the delay-broadcast section is shown to drivers.
///
/// Off until the backend can produce time estimates. The three buttons have
/// no handlers behind them, so a driver reporting a delay would change
/// nothing and no parent would ever be told — worse than the feature being
/// absent. Flip this to `true` to bring the section back; the widget and its
/// strings are kept intact for that.
const bool kBroadcastStatusEnabled = false;

class DvBroadcastStatus extends StatelessWidget {
  const DvBroadcastStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: AppBorders.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),

      padding: EdgeInsets.all(20),
      margin: EdgeInsetsDirectional.only(start: 20, end: 20, top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.broadcast_on_home),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
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
                    backgroundColor: AppColors.dangerTint,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    side: BorderSide(color: AppColors.dangerRed, width: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
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
                    backgroundColor: AppColors.warningTint,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    side: BorderSide(
                      color: AppColors.warningYellow,
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
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
                      borderRadius: BorderRadius.circular(AppRadius.control),
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
