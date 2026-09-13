import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, visibleForTesting;

/// Single place to configure where the Pasaty backend lives.
///
/// Release builds must talk to a real HTTPS host: iOS App Transport Security
/// and the Android network security config both refuse cleartext, and a build
/// pointing at loopback is a guaranteed store rejection (the reviewer just
/// sees a connection error at login).
///
/// Resolution order:
///  1. `--dart-define=API_BASE_URL=...` — wins everywhere. Use this to point a
///     physical device at a dev machine on the LAN, or to build against
///     staging:
///       flutter run --dart-define=API_BASE_URL=http://192.168.1.31:3000
///  2. Debug builds fall back to loopback for local development. On the
///     Android emulator 10.0.2.2 is the host machine; on iOS simulator and
///     macOS 127.0.0.1 is the host already.
///  3. Release builds use [_production] and nothing else.
class ApiConfig {
  const ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Production backend. MUST be an https:// host before shipping.
  ///
  /// TODO(release): replace with the real production hostname. Until then
  /// release builds fail fast at the first request rather than silently
  /// pointing at a host that cannot exist on a user's phone.
  static const String _production = '';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    if (kDebugMode) {
      // Local development only — never reached in a release build.
      if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
      return 'http://127.0.0.1:3000';
    }

    if (_production.isEmpty) {
      throw StateError(
        'No production API base URL is configured. Set ApiConfig._production '
        'to the https:// backend host, or build with '
        '--dart-define=API_BASE_URL=https://...',
      );
    }
    return _production;
  }

  /// Exposed for the compliance test, which asserts that whatever ships is
  /// HTTPS and is not a loopback address.
  @visibleForTesting
  static String get productionUrl => _production;
}
