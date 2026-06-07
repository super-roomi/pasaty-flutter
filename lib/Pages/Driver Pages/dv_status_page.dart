import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mockup/Widgets/Driver%20Widgets/dv_broadcast_status.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_delivery_widget_active.dart';
import 'package:mockup/Widgets/Driver%20Widgets/dv_delivery_widget_passive.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool _drivingIsStarted = false;

  void _onDrivingStarted() {
    setState(() => _drivingIsStarted = true);
  }

  void _onDrivingEnded(int elapsedSeconds) {
    setState(() => _drivingIsStarted = false);
    _sendSession(elapsedSeconds);
  }

  Future<void> _sendSession(int elapsedSeconds) async {
    final payload = {
      'totalSeconds': elapsedSeconds,
      'minutes': elapsedSeconds ~/ 60,
      'seconds': elapsedSeconds % 60,
      'endedAt': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('https://doodoo.kaka.com/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        debugPrint('API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to send session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _drivingIsStarted
          ? ListView(
        key: const ValueKey(true),
        children: [
          DvDeliveryWidgetActive(onEnd: _onDrivingEnded), // ← onEnd
          const DvBroadcastStatus(),
        ],
      )
          : ListView(
        key: const ValueKey(false),
        children: [
          DvDeliveryWidgetPassive(onStart: _onDrivingStarted),
        ],
      ),
    );
  }
}