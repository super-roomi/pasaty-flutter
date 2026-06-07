import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';

class PrSettingsPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;

  const PrSettingsPage({super.key, required this.onLocaleChange});

  @override
  State<PrSettingsPage> createState() => _PrSettingsPageState();
}

class _PrSettingsPageState extends State<PrSettingsPage> {
  late Locale _selectedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale = Localizations.localeOf(context); // grab current on init
  }

  String _localeLabel(Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧 ${l10n.englishLanguage}';
      case 'ar':
        return '🇸🇦 ${l10n.arabicLanguage}';
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              l10n.language,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: L10n.all.map((locale) {
                final isSelected =
                    _selectedLocale.languageCode ==
                    locale.languageCode; // ← fixed
                final isLast = L10n.all.last == locale;

                return Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(_localeLabel(locale)),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(
                          () => _selectedLocale = locale,
                        ); // ← update checkmark locally
                        widget.onLocaleChange(
                          locale,
                        ); // ← update app locale globally
                      },
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 16,
                        color: Colors.grey.shade300,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
