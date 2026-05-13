import 'package:flutter/material.dart';

class PrStatusWidget extends StatefulWidget {
  const PrStatusWidget({super.key});

  @override
  State<PrStatusWidget> createState() => _PrStatusWidgetState();
}

class _PrStatusWidgetState extends State<PrStatusWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(20),
            color: Color(0xFF1A2B48),
          ),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text("CURRENT STATUS", style: TextStyle(color: Colors.grey, fontSize: 18),),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(50)
                ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text("60-Meter Road", style: TextStyle(color: Colors.white),),
                  ))
            ],) //Contains Status & Text Location
          ],
          ),

        )
      ],
    );
  }
}
