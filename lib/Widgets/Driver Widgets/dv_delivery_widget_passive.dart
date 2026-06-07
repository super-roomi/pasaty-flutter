import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class DvDeliveryWidgetPassive extends StatefulWidget {
  final VoidCallback onStart;
  const DvDeliveryWidgetPassive({super.key, required this.onStart});

  @override
  State<DvDeliveryWidgetPassive> createState() =>
      _DvDeliveryWidgetPassiveState();
}

class _DvDeliveryWidgetPassiveState extends State<DvDeliveryWidgetPassive> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
        color: Color(0xFF1A2B48),
      ),
      child: Column(
        spacing: 5,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.directions_bus_filled_outlined, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: Text(
                  l10n.busNumber('13'),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              spacing: 15,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    //alignment: Alignment.center,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.totalStops,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          Text(
                            l10n.totalStopsCount(15),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    //alignment: Alignment.center,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.approxDuration,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          Text(
                            l10n.durationMinutes(47),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.readyToGo),
                  content: Text(l10n.confirmStudentsOnBoard),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                      ), //cancels operation, nothing happens
                      child: Text(l10n.cancel, style: TextStyle(color: Colors.red),),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onStart();
                      }, //Closes the page, updates onStart
                      child: Text(l10n.ok),
                    ),
                  ],
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.play_arrow_outlined),
              label: Text(l10n.startSession.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}
