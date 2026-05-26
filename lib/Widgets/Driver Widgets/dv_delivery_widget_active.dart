import 'package:flutter/material.dart';
import 'package:mockup/Colors/AppColors.dart';

class DvDeliveryWidgetActive extends StatefulWidget {

  //--------------------Manage state for showing passive vs active states-------
  final VoidCallback onStart; //changes state in parent dv_status_page
  const DvDeliveryWidgetActive({super.key, required this.onStart});
  //----------------------------------------------------------------------------



  @override
  State<DvDeliveryWidgetActive> createState() => _DvDeliveryWidgetActiveState();
}

class _DvDeliveryWidgetActiveState extends State<DvDeliveryWidgetActive> {
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
            "00:00:00",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Are your sure?'),
                content: Text('Please confirm you want to end your session.'),
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
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.stop_circle_outlined, color: Colors.white),
            label: Text("END SESSION", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
