import 'package:flutter/foundation.dart' show kReleaseMode;

/// Where map tiles come from.
///
/// The token is supplied at build time, never committed:
///
///   flutter build apk --release \
///     --dart-define=MAPBOX_TOKEN=pk.your_public_token
///
/// It must be a **public** token (`pk.…`), not the secret token the backend
/// uses for the Directions API. Anything compiled into the binary is
/// extractable with `strings`, so treat this value as published and
/// URL-restrict it in the Mapbox dashboard.
class MapConfig {
  static const String _token = String.fromEnvironment('MAPBOX_TOKEN');

  /// Override with e.g. `mapbox/light-v11` at build time.
  static const String _style = String.fromEnvironment(
    'MAPBOX_STYLE',
    defaultValue: 'mapbox/streets-v12',
  );

  static bool get hasMapbox => _token.isNotEmpty;

  /// OSMF's public tiles are a donation-funded community resource whose usage
  /// policy does not cover a distributed app. They stay available in debug
  /// builds only, so local work does not need a token — a release build
  /// without one renders no basemap rather than silently falling back onto
  /// servers we are not entitled to use.
  static bool get canUseOsmFallback => !kReleaseMode;

  static bool get isConfigured => hasMapbox || canUseOsmFallback;

  /// 256-sized tiles at @2x give retina detail without needing a zoom offset.
  static String get urlTemplate => hasMapbox
      ? 'https://api.mapbox.com/styles/v1/$_style/tiles/256/{z}/{x}/{y}@2x'
            '?access_token=$_token'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static int get maxZoom => hasMapbox ? 22 : 19;
}
