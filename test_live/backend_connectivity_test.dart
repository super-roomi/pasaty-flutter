import 'package:flutter_test/flutter_test.dart';

import 'package:mockup/services/auth_service.dart';

/// Live check against the local backend — requires the Node server to be
/// running on http://127.0.0.1:3000. Run with:
///   flutter test test/backend_connectivity_test.dart
void main() {
  test('AuthService reaches the backend and gets a real auth response',
      () async {
    try {
      await AuthService.login('07700000000', 'definitely-wrong-password');
      fail('Expected the backend to reject bogus credentials');
    } on AuthException catch (e) {
      // A 401 means the request crossed the wire and the backend's login
      // logic answered. A network failure would throw a different error.
      expect(e.statusCode, 401);
      expect(e.message, 'Invalid Credentials');
    }
  });
}
