import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Single place to configure where the Pasaty backend lives.
///
/// The backend listens on your Mac at http://127.0.0.1:3000, but what
/// address reaches it depends on where the app itself is running:
///  - iOS simulator / macOS / web: 127.0.0.1 is the Mac itself — works.
///  - Android emulator: 127.0.0.1 is the emulator; 10.0.2.2 is the Mac.
///  - Physical phone (iPhone/Android): 127.0.0.1 is the phone; use the
///    Mac's LAN IP instead (same Wi-Fi network required).
///
/// For physical devices, pass the LAN IP at launch without editing code:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.31:3000
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://127.0.0.1:3000';
  }
}
