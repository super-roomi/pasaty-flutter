import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import '../../l10n/app_localizations.dart';

class DvDeliveryWidgetActive extends StatefulWidget {
  final void Function(int elapsedSeconds) onEnd; // ← takes elapsed seconds
  const DvDeliveryWidgetActive({super.key, required this.onEnd});

  @override
  State<DvDeliveryWidgetActive> createState() => _DvDeliveryWidgetActiveState();
}

class _DvDeliveryWidgetActiveState extends State<DvDeliveryWidgetActive> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  String get _display {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1A2B48),
      ),
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_outlined, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  l10n.activeDeliverySession.toUpperCase(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          Text(
            _display,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.endSessionDialogTitle),
                content: Text(l10n.endSessionDialogMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel,
                        style: const TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      Navigator.pop(context);
                      widget.onEnd(_elapsedSeconds); // ← send time to parent
                    },
                    child: Text(l10n.ok),
                  ),
                ],
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
            label: Text(
              l10n.endSession.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}