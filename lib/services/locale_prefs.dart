import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen app language across restarts.
///
/// The locale is picked at login (or in settings) and stored by language
/// code, so it survives logout, login, and full app restarts.
class LocalePrefs {
  LocalePrefs._();

  static const _key = 'locale_language_code';

  /// Reads the saved locale, or null if the user never chose one.
  static Future<Locale?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == null) return null;
    return Locale(code);
  }

  /// Stores the chosen locale by its language code.
  static Future<void> save(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
