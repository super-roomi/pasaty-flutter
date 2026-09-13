@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/services/api_config.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:mockup/services/socket_service.dart';

/// The failure a driver could not see.
///
/// socket.io buffers an emit on a socket that is up-but-unanswering and never
/// calls the ack, so before the timeout existed the app could report for an
/// entire run without a single position reaching the server — and show a
/// completely normal screen while doing it.
///
/// Run against a server that accepts the connection and never acks:
///   node silent_server_tmp.js
///   flutter test --dart-define=API_BASE_URL=http://127.0.0.1:4600 \
///     --tags integration test/socket_ack_timeout_test.dart
void main() {
  test('an unanswered position report is reported as a timeout', () async {
    expect(ApiConfig.baseUrl, contains('127.0.0.1'));
    AuthSession.instance.accessToken = 'integration-test-token';

    final service = SocketService.instance;
    var timedOut = false;
    var answered = false;

    service.emitDriverLocation(
      {
        'routeid': 1,
        'latitude': 35.5,
        'longitude': 45.4,
        'accuracy': 10.0,
        'speed': 0.0,
        'heading': 0.0,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      },
      onStored: () => answered = true,
      onStale: () => answered = true,
      onRefused: (_) => answered = true,
      onTimeout: () => timedOut = true,
    );

    // Slightly longer than the 12s ack window.
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (!timedOut && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    expect(
      timedOut,
      isTrue,
      reason: 'the unanswered report should have surfaced as a timeout',
    );
    expect(answered, isFalse, reason: 'the server never answered');

    service.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
