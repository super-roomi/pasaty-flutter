/// Single place to configure where the Pasaty backend lives.
///
/// 127.0.0.1 works for iOS simulator, macOS, and web. On the Android
/// emulator use 10.0.2.2 instead, and for a real device use your
/// machine's LAN IP, e.g. http://192.168.1.x:3000
class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:3000';
}
