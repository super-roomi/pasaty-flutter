import 'package:flutter/material.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_broadcast_status.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_delivery_widget_active.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_delivery_widget_passive.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_student_card.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool _drivingIsStarted = true;

  void _onDrivingStarted() {
    setState(() => _drivingIsStarted = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(duration: Duration(milliseconds: 300),
      child: _drivingIsStarted
          ? ListView(key: ValueKey(true),children: [DvDeliveryWidgetActive(onStart: _onDrivingStarted), DvBroadcastStatus()],)
          : ListView(key: ValueKey(false), children: [DvDeliveryWidgetPassive()],),
    );
  }
}
