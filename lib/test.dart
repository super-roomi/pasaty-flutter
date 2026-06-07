import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

Future<http.Response> fetchAlbum() {
  return http.get(Uri.parse('http://127.0.0.1:3000/test'));
}

class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ElevatedButton(onPressed: fetchAlbum, child: Text(l10n.test)),
    );
  }
}
