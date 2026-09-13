import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockup/services/api_client.dart';
import 'package:mockup/services/auth_service.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the two service-layer criticals:
///
///  * a burst of parallel 401s must trigger exactly ONE refresh, because the
///    backend rotates the refresh cookie and the losers of that race would
///    otherwise replay a dead cookie and tear down a valid session;
///  * a non-JSON body (proxy error page, captive portal, empty 204) must
///    surface as ApiException/AuthException, never as a raw FormatException
///    that escapes every `on`-clause the callers wrote.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AuthSession.persist() writes through flutter_secure_storage, whose plugin
  // channel does not exist in a unit test. Stub it so the code under test can
  // run its real persistence path.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storage = <String, String>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'write':
              storage[call.arguments['key'] as String] =
                  call.arguments['value'] as String;
              return null;
            case 'read':
              return storage[call.arguments['key'] as String];
            case 'delete':
              storage.remove(call.arguments['key'] as String);
              return null;
            case 'readAll':
              return storage;
            case 'deleteAll':
              storage.clear();
              return null;
          }
          return null;
        });
    storage.clear();
    final session = AuthSession.instance;
    session.accessToken = null;
    session.refreshTokenCookie = null;
    session.user = null;
    session.onSessionExpired = null;
    AuthService.resetForTesting();
    ApiClient.resetForTesting();
  });

  group('refresh single-flight', () {
    test(
      'N concurrent refresh() calls issue exactly one HTTP request',
      () async {
        var refreshCalls = 0;
        final gate = Completer<void>();

        AuthService.resetForTesting(
          withClient: MockClient((request) async {
            refreshCalls++;
            // Hold the first refresh open so the others pile up behind it,
            // which is exactly the cold-start situation.
            await gate.future;
            return http.Response(
              jsonEncode({'accessToken': 'new-token'}),
              200,
              headers: {'set-cookie': 'refreshToken=rotated; Path=/'},
            );
          }),
        );
        AuthSession.instance.refreshTokenCookie = 'refreshToken=original';

        final all = Future.wait([
          AuthService.refresh(),
          AuthService.refresh(),
          AuthService.refresh(),
          AuthService.refresh(),
          AuthService.refresh(),
        ]);
        gate.complete();
        await all;

        expect(
          refreshCalls,
          1,
          reason: 'the rotated cookie must be fetched once',
        );
        expect(AuthSession.instance.accessToken, 'new-token');
        expect(AuthSession.instance.refreshTokenCookie, 'refreshToken=rotated');
      },
    );

    test(
      'a later refresh after the first completes starts a new request',
      () async {
        var refreshCalls = 0;
        AuthService.resetForTesting(
          withClient: MockClient((request) async {
            refreshCalls++;
            return http.Response(
              jsonEncode({'accessToken': 't$refreshCalls'}),
              200,
            );
          }),
        );
        AuthSession.instance.refreshTokenCookie = 'refreshToken=original';

        await AuthService.refresh();
        await AuthService.refresh();

        // The lock must not latch — it only collapses *concurrent* callers.
        expect(refreshCalls, 2);
      },
    );

    test('a failed refresh releases the lock', () async {
      var calls = 0;
      AuthService.resetForTesting(
        withClient: MockClient((request) async {
          calls++;
          return http.Response(jsonEncode({'message': 'nope'}), 500);
        }),
      );
      AuthSession.instance.refreshTokenCookie = 'refreshToken=original';

      await expectLater(AuthService.refresh(), throwsA(isA<AuthException>()));
      await expectLater(AuthService.refresh(), throwsA(isA<AuthException>()));
      expect(calls, 2, reason: 'a stuck lock would deadlock every later call');
    });
  });

  group('non-JSON bodies', () {
    test('ApiClient turns an HTML error page into ApiException', () async {
      ApiClient.resetForTesting(
        withClient: MockClient(
          (_) async => http.Response('<html>502 Bad Gateway</html>', 502),
        ),
      );

      await expectLater(
        ApiClient.get('/v1/protected/students'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 502),
        ),
      );
    });

    test('ApiClient tolerates an empty body', () async {
      ApiClient.resetForTesting(
        withClient: MockClient((_) async => http.Response('', 200)),
      );

      expect(await ApiClient.get('/v1/protected/students'), isEmpty);
    });

    test(
      'login on an HTML body throws AuthException, not FormatException',
      () async {
        AuthService.resetForTesting(
          withClient: MockClient(
            (_) async => http.Response('<html>gateway timeout</html>', 504),
          ),
        );

        await expectLater(
          AuthService.login('07700000000', 'pw'),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test('login rejects a 200 that is missing accessToken', () async {
      AuthService.resetForTesting(
        withClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'user': {'id': 1},
            }),
            200,
          ),
        ),
      );

      await expectLater(
        AuthService.login('07700000000', 'pw'),
        throwsA(isA<AuthException>()),
      );
    });

    test('refresh on a non-JSON body throws AuthException', () async {
      AuthService.resetForTesting(
        withClient: MockClient((_) async => http.Response('not json', 200)),
      );
      AuthSession.instance.refreshTokenCookie = 'refreshToken=original';

      await expectLater(AuthService.refresh(), throwsA(isA<AuthException>()));
    });
  });
}
