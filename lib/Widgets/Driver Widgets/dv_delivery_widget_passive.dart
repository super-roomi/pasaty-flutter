import 'package:flutter/material.dart';

import '../../Colors/AppColors.dart';

class DvDeliveryWidgetPassive extends StatefulWidget {
  final VoidCallback onStart;
  DvDeliveryWidgetPassive({super.key, required this.onStart});

  @override
  State<DvDeliveryWidgetPassive> createState() =>
      _DvDeliveryWidgetPassiveState();
}

class _DvDeliveryWidgetPassiveState extends State<DvDeliveryWidgetPassive> {
  @override
  Widget build(BuildContext context) {
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
                child: Text("BUS #13", style: TextStyle(color: Colors.grey)),
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
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey
                        ),
                        borderRadius: BorderRadius.circular(10)
                    ),

                    //alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(left:8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Stops",
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          Text("15", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey
                      ),
                        borderRadius: BorderRadius.circular(10)
                    ),

                    //alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(left:8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Approx. Duration",
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          Text("47 minutes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top:5.0),
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Ready to Go?'),
                  content: Text(
                    "Please confirm that all present students are on board.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                      ), //cancels operation, nothing happens
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onStart();
                      }, //Closes the page, updates onStart
                      child: Text('OK'),
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
              label: Text("START SESSION"),
            ),
          ),
        ],
      ),
    );
  }
}
