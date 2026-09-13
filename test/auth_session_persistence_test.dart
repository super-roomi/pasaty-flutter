import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the platform Keychain / EncryptedSharedPreferences.
///
/// flutter_secure_storage has no `setMockInitialValues` equivalent, so the
/// MethodChannel is faked directly. Keys mirror the plugin's wire format.
class _FakeSecureStore {
  final Map<String, String> values = {};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
        final key = args['key'] as String?;
        switch (call.method) {
          case 'read':
            return values[key];
          case 'write':
            values[key!] = args['value'] as String;
            return null;
          case 'delete':
            values.remove(key);
            return null;
          case 'deleteAll':
            values.clear();
            return null;
          case 'readAll':
            return Map<String, String>.from(values);
          case 'containsKey':
            return values.containsKey(key);
        }
        return null;
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSecureStore store;

  setUp(() {
    store = _FakeSecureStore()..install();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await AuthSession.instance.clear();
  });

  group('restore', () {
    test('returns false when nothing was ever stored', () async {
      expect(await AuthSession.instance.restore(), isFalse);
      expect(AuthSession.instance.isLoggedIn, isFalse);
    });

    test('rehydrates a persisted session', () async {
      final session = AuthSession.instance;
      session.accessToken = 'access-abc';
      session.refreshTokenCookie = 'refreshToken=cookie-xyz';
      session.user = const AuthUser(
        id: 7,
        firstName: 'Layla',
        lastName: 'Hassan',
        phone: '07701112222',
        role: UserRole.parent,
      );
      await session.persist();

      // Simulate a cold start: the marker survives, the in-memory copy does not.
      SharedPreferences.setMockInitialValues({'auth_install_marker': true});
      session.accessToken = null;
      session.refreshTokenCookie = null;
      session.user = null;

      expect(await session.restore(), isTrue);
      expect(session.refreshTokenCookie, 'refreshToken=cookie-xyz');
      expect(session.user?.role, UserRole.parent);
      expect(session.user?.name, 'Layla Hassan');
    });

    test('treats a missing refresh cookie as no session', () async {
      // An access token alone cannot outlive its ~15 minute lifetime, so a
      // half-restored session would just fail on the first request.
      store.values['auth_access_token'] = 'access-only';
      SharedPreferences.setMockInitialValues({'auth_install_marker': true});

      expect(await AuthSession.instance.restore(), isFalse);
    });
  });

  group('reinstall purge', () {
    test('drops credentials left in the Keychain by a previous install',
        () async {
      // iOS keeps Keychain items when the app is deleted; SharedPreferences
      // goes with it. Marker absent + store populated == leftover credentials.
      store.values
        ..['auth_access_token'] = 'stale-access'
        ..['auth_refresh_cookie'] = 'refreshToken=stale'
        ..['auth_user'] = '{"id":1,"firstName":"Prev","lastName":"Owner",'
            '"phone":"0770","role":"parent"}';
      SharedPreferences.setMockInitialValues({});

      expect(await AuthSession.instance.restore(), isFalse);
      expect(store.values, isEmpty,
          reason: 'previous install credentials must not survive a reinstall');
      expect(AuthSession.instance.isLoggedIn, isFalse);
    });

    test('does not purge on an ordinary relaunch', () async {
      final session = AuthSession.instance;
      session.refreshTokenCookie = 'refreshToken=live';
      await session.persist();
      SharedPreferences.setMockInitialValues({'auth_install_marker': true});

      expect(await session.restore(), isTrue);
      expect(store.values['auth_refresh_cookie'], 'refreshToken=live');
    });

    test('sets the marker so the next launch is not treated as a reinstall',
        () async {
      SharedPreferences.setMockInitialValues({});
      await AuthSession.instance.restore();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('auth_install_marker'), isTrue);
    });
  });

  group('clear', () {
    test('wipes both memory and the secure store', () async {
      final session = AuthSession.instance;
      session.accessToken = 'a';
      session.refreshTokenCookie = 'refreshToken=b';
      await session.persist();

      await session.clear();

      expect(session.isLoggedIn, isFalse);
      expect(store.values, isEmpty);
    });
  });

  group('Android backup is disabled for the credential store', () {
    test('manifest opts out of Auto Backup', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:dataExtractionRules='));
    });

    test('device transfer excludes the secure storage file', () {
      // allowBackup="false" does not cover Android 12+ device-to-device
      // transfer; that is governed by the extraction rules.
      final rules =
          File('android/app/src/main/res/xml/data_extraction_rules.xml')
              .readAsStringSync();
      expect(rules, contains('<device-transfer>'));
      expect(rules, contains('FlutterSecureStorage.xml'));
    });
  });
}
