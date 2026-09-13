import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors the backend's role enum (utils/enum.js).
class UserRole {
  static const String admin = 'admin';
  static const String user = 'user';
  static const String parent = 'parent';
  static const String driver = 'driver';
}

class AuthUser {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String role;

  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
  });

  String get name => lastName.isEmpty ? firstName : '$firstName $lastName';

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'role': role,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    firstName: (json['firstName'] ?? '') as String,
    lastName: (json['lastName'] ?? '') as String,
    phone: (json['phone'] ?? '') as String,
    role: (json['role'] ?? '') as String,
  );
}

/// The session holding the tokens returned by the backend.
///
/// The refresh token is issued as an httpOnly cookie, which the `http`
/// package does not persist on mobile, so its raw cookie value is kept
/// here and sent back manually on /refresh and /logout.
///
/// Persisted, not in-memory only: iOS and Android freely kill a backgrounded
/// process, and an in-memory session meant every such kill looked to the user
/// like being logged out. [restore] rehydrates it at startup.
///
/// Stored via flutter_secure_storage (Keychain / EncryptedSharedPreferences)
/// rather than SharedPreferences — a refresh token is a long-lived credential
/// and does not belong in a plaintext plist/XML file that any backup or
/// rooted-device dump would expose.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _storage = FlutterSecureStorage(
    // Android: defaults are already AES-GCM with RSA-OAEP key wrapping backed
    // by the KeyStore (the old `encryptedSharedPreferences` flag was removed
    // in v11 because encryption is no longer opt-in).
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      // Readable only after the first post-boot unlock, and never synced to
      // iCloud or restored onto a different device.
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_cookie';
  static const _kUser = 'auth_user';

  /// Lives in SharedPreferences, deliberately — see [_purgeIfReinstalled].
  static const _kInstallMarker = 'auth_install_marker';

  String? accessToken;
  String? refreshTokenCookie;
  AuthUser? user;

  /// Invoked when the backend rejects the refresh token, i.e. the session is
  /// gone for good. The UI layer sets this to send the user back to login;
  /// without it a restored-but-expired session would leave whichever shell
  /// was opened stuck showing errors on every request.
  void Function()? onSessionExpired;

  bool get isLoggedIn => accessToken != null;

  /// Loads any previously saved session. Returns true when one was found.
  ///
  /// A restored access token is very likely expired (they are short-lived);
  /// that is fine, because [ApiClient] refreshes once on the first 401 using
  /// the refresh cookie, which is the value that actually keeps the user
  /// signed in across restarts.
  Future<bool> restore() async {
    try {
      await _purgeIfReinstalled();

      final refresh = await _storage.read(key: _kRefresh);
      // Without the refresh cookie the session cannot outlive the access
      // token, so treat it as no session at all rather than a half-restored
      // one that fails on the first request.
      if (refresh == null) return false;

      accessToken = await _storage.read(key: _kAccess);
      refreshTokenCookie = refresh;

      final rawUser = await _storage.read(key: _kUser);
      if (rawUser != null) {
        user = AuthUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      }
      return true;
    } catch (_) {
      // Corrupt or unreadable store (e.g. keychain reset): start clean rather
      // than trapping the user on a broken session.
      await clear();
      return false;
    }
  }

  /// Drops any credentials left over from a previous installation.
  ///
  /// Deleting an iOS app does **not** clear its Keychain items, so a reinstall
  /// would find the previous user's refresh token and sign whoever is holding
  /// the phone straight back into that account — no password, no prompt. On a
  /// handed-down, resold or shared device that hands a stranger a live view of
  /// a child's route and attendance.
  ///
  /// SharedPreferences *is* removed on uninstall, which is exactly what makes
  /// it usable as the "this install has run before" marker: marker absent but
  /// Keychain populated means the store outlived its app.
  ///
  /// Harmless on Android, where uninstall already clears both.
  Future<void> _purgeIfReinstalled() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kInstallMarker) ?? false) return;

    await Future.wait([
      _storage.delete(key: _kAccess),
      _storage.delete(key: _kRefresh),
      _storage.delete(key: _kUser),
    ]);
    await prefs.setBool(_kInstallMarker, true);
  }

  /// Writes the current session to secure storage.
  Future<void> persist() async {
    await Future.wait([
      _write(_kAccess, accessToken),
      _write(_kRefresh, refreshTokenCookie),
      _write(_kUser, user == null ? null : jsonEncode(user!.toJson())),
    ]);
  }

  /// Updates just the access token, after a refresh.
  Future<void> persistAccessToken() => _write(_kAccess, accessToken);

  Future<void> clear() async {
    accessToken = null;
    refreshTokenCookie = null;
    user = null;
    await Future.wait([
      _storage.delete(key: _kAccess),
      _storage.delete(key: _kRefresh),
      _storage.delete(key: _kUser),
    ]);
  }

  static Future<void> _write(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}
