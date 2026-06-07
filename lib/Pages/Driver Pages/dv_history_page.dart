import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class DvHistoryPage extends StatefulWidget {
  const DvHistoryPage({super.key});

  @override
  State<DvHistoryPage> createState() => _DvHistoryPageState();
}

class _DvHistoryPageState extends State<DvHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Text(l10n.history));
  }
}
