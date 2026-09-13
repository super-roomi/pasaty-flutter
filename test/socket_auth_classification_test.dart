import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/services/socket_service.dart';

/// Which connect failures justify burning a refresh token.
///
/// Before this distinction existed the socket refreshed on *every* connect
/// error. On a bus with patchy signal that means a token rotation per dropped
/// connection — hammering /auth/refresh and churning the refresh chain at a
/// rate set by signal strength rather than by session length.
void main() {
  group('connect error classification', () {
    test('the backend\'s own handshake rejections count as auth', () {
      // Verbatim from utils/authMiddleware.js authenticateSocket().
      for (final message in const [
        'Authentication required',
        'User not found',
        'Session terminated. Please login again.',
        'jwt expired',
        'invalid token',
      ]) {
        expect(
          SocketService.debugIsAuthRejection(message),
          isTrue,
          reason: '"$message" should trigger a refresh',
        );
      }
    });

    test('socket.io transport failures do not', () {
      for (final message in const [
        'timeout',
        'xhr poll error',
        'websocket error',
      ]) {
        expect(
          SocketService.debugIsAuthRejection(message),
          isFalse,
          reason: '"$message" is a network problem, not an auth one',
        );
      }
    });

    test('a transport failure wins even when it mentions a socket', () {
      // Real socket.io errors can carry both words; the transport reading has
      // to win or we are back to refreshing on every blip.
      expect(
        SocketService.debugIsAuthRejection(
          'timeout while opening authenticated websocket',
        ),
        isFalse,
      );
    });
  });
}
