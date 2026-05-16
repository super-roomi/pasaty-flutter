import 'package:flutter/material.dart';

import '../../Colors/AppColors.dart';

class DvDeliveryWidgetPassive extends StatelessWidget {
  const DvDeliveryWidgetPassive({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
        color: Color(0xFF1A2B48),
      ),
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.access_time_outlined, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "ACTIVE DELIVERY SESSION",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          Text(
            "00:42:27",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          Text(
            "En route to Saholaka",
            style: TextStyle(color: Colors.grey),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => {},
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(220, 50),
                  backgroundColor: AppColors.dangerRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.stop_circle_outlined, color: Colors.white),
                label: Text(
                  "END SESSION",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              ElevatedButton(
                onPressed: () => {},
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(80, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                ),
                child: Text("SOS"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
