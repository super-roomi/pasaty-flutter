import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class PrSchedulePage extends StatefulWidget {
  const PrSchedulePage({super.key});

  @override
  State<PrSchedulePage> createState() => _PrSchedulePageState();
}

class _PrSchedulePageState extends State<PrSchedulePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.settings_outlined, size: 26),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settings,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.managePersonalInformation,
                    style: TextStyle(height: 0.8),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_sharp),
          ],
        ),
      ),
    );
  }
}
