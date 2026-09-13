import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import 'api_client.dart' show ApiErrorKind, kindForStatus;
import 'api_config.dart';
import 'auth_session.dart';
import 'driver_location_reporter.dart';
import 'push_service.dart';
import 'socket_service.dart';

/// Failure from /v1/auth/*.
///
/// [message] is diagnostic text (the backend's English prose, or a note about
/// a malformed payload). It is for logs and debug builds — user-facing copy is
/// localized from [kind] by `errorText` in `lib/Util/error_text.dart`.
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorKind kind;

  AuthException(this.message, {this.statusCode, ApiErrorKind? kind})
    : kind = kind ?? kindForStatus(statusCode);

  @override
  String toString() => message;
}

/// Talks to the backend's /v1/auth/* routes.
///
/// POST /v1/auth/register is intentionally NOT implemented here: accounts
/// are created by admins through the web dashboard only. The app can only
/// log existing users in.
class AuthService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// The HTTP client used for every auth call.
  ///
  /// A single long-lived client (rather than the implicit per-call one the
  /// top-level `http.post` helpers create) also reuses connections across the
  /// parallel request fan-outs elsewhere in the app. Tests swap in a
  /// `MockClient`; see [resetForTesting].
  static http.Client client = http.Client();

  /// Restores a clean static state between tests — the client and the
  /// single-flight refresh lock both outlive an individual test otherwise.
  @visibleForTesting
  static void resetForTesting({http.Client? withClient}) {
    client = withClient ?? http.Client();
    _inFlightRefresh = null;
  }

  /// Logs in with phone + password and stores the session.
  ///
  /// The backend puts the role inside the JWT payload (not in the user
  /// object of the response), so it is read by decoding the access token.
  static Future<AuthUser> login(String phone, String password) async {
    final uri = Uri.parse('$_baseUrl/v1/auth/login');

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    final body = _decodeBody(response);

    if (response.statusCode != 200) {
      throw AuthException(_extractError(body), statusCode: response.statusCode);
    }

    final accessToken = body['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw AuthException(
        'Login response missing accessToken',
        statusCode: 200,
        kind: ApiErrorKind.badResponse,
      );
    }
    final payload = _decodeJwtPayload(accessToken);
    final userJson = body['user'];
    if (userJson is! Map<String, dynamic>) {
      throw AuthException(
        'Login response missing user object',
        statusCode: 200,
        kind: ApiErrorKind.badResponse,
      );
    }

    // Login responds with {id, Fname, Lname, phone} (authController.js).
    // Coerced rather than cast: a contract change must not surface to the
    // user as "check your internet" (which is what an uncaught TypeError
    // becomes at the login page's generic catch).
    final id = userJson['id'];
    final user = AuthUser(
      id: id is int ? id : (id as num?)?.toInt() ?? _bad('user.id'),
      firstName: (userJson['Fname'] ?? '').toString(),
      lastName: (userJson['Lname'] ?? '').toString(),
      phone: (userJson['phone'] ?? '').toString(),
      role: (payload['role'] ?? '').toString(),
    );

    final session = AuthSession.instance;
    session.accessToken = accessToken;
    session.refreshTokenCookie = _extractRefreshCookie(response);
    session.user = user;
    // Survives the OS killing a backgrounded app.
    await session.persist();

    return user;
  }

  /// In-flight refresh, shared by every concurrent caller.
  ///
  /// The backend rotates the refresh cookie, so the first refresh invalidates
  /// the cookie the others are holding. Without this lock, a burst of parallel
  /// 401s (the parent roster fans out one request per child, history batches
  /// five at a time, and the socket recovers separately) would fire N refreshes
  /// — the first succeeds and the rest replay a dead cookie, get 401, and tear
  /// down a perfectly good session. Guaranteed on cold start, because
  /// [AuthSession.restore] deliberately restores an already-expired access
  /// token.
  static Future<void>? _inFlightRefresh;

  /// True while a refresh is running. Lets callers that must not queue behind
  /// one (e.g. socket recovery) skip instead of piling up.
  static bool get isRefreshing => _inFlightRefresh != null;

  /// Exchanges the stored refresh-token cookie for a new access token.
  ///
  /// Callers arriving mid-refresh await the same future and then retry with
  /// whatever token it produced.
  static Future<void> refresh() {
    return _inFlightRefresh ??= _refresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  static Future<void> _refresh() async {
    final session = AuthSession.instance;
    final cookie = session.refreshTokenCookie;
    if (cookie == null) {
      throw AuthException(
        'No refresh token stored',
        statusCode: 401,
        kind: ApiErrorKind.unauthorized,
      );
    }

    final response = await client.post(
      Uri.parse('$_baseUrl/v1/auth/refresh'),
      headers: {'Cookie': cookie},
    );

    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      // The refresh token is expired or was revoked server-side. Drop the
      // stored session so the next launch goes straight to login instead of
      // retrying a credential that can never work again.
      if (response.statusCode == 401 || response.statusCode == 403) {
        await session.clear();
        DriverLocationReporter.instance.stop();
        SocketService.instance.disconnect();
        session.onSessionExpired?.call();
      }
      throw AuthException(_extractError(body), statusCode: response.statusCode);
    }

    final token = body['accessToken'];
    if (token is! String || token.isEmpty) {
      throw AuthException(
        'Refresh response missing accessToken',
        statusCode: 200,
        kind: ApiErrorKind.badResponse,
      );
    }
    session.accessToken = token;
    // Refresh may also rotate the cookie; keep the newest one.
    final rotated = _extractRefreshCookie(response);
    if (rotated != null) {
      session.refreshTokenCookie = rotated;
      await session.persist();
    } else {
      await session.persistAccessToken();
    }
  }

  /// Revokes the refresh token server-side and clears the local session.
  static Future<void> logout() async {
    final session = AuthSession.instance;
    final cookie = session.refreshTokenCookie;

    // Sent in the logout body rather than via DELETE /v1/devices — one call
    // instead of two, and ownership is taken from the refresh cookie so it
    // can only ever remove a device belonging to whoever is signing out.
    // Leaving the row behind would mean the next person to use this phone
    // gets notifications about another family's children.
    final deviceToken = PushService.instance.tokenForLogout;

    try {
      await client.post(
        Uri.parse('$_baseUrl/v1/auth/logout'),
        headers: {'Content-Type': 'application/json', 'Cookie': ?cookie},
        body: jsonEncode({'device_token': ?deviceToken}),
      );
    } finally {
      DriverLocationReporter.instance.stop();
      SocketService.instance.disconnect();
      await PushService.instance.onSignedOut();
      // Also wipes the persisted copy — otherwise the next launch would
      // restore the session the user just signed out of.
      await session.clear();
    }
  }

  /// Headers for authenticated requests to /v1/protected/* routes.
  static Map<String, String> authHeaders() {
    final token = AuthSession.instance.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Never _bad(String field) => throw AuthException(
    'Malformed field "$field" in server response',
    kind: ApiErrorKind.badResponse,
  );

  /// Decodes a response body that is *supposed* to be a JSON object.
  ///
  /// Anything can sit between the app and the API — a reverse proxy 502 page,
  /// a captive portal, an empty 204. Those return HTML or nothing, and a bare
  /// `jsonDecode` throws [FormatException], which is neither an
  /// [AuthException] nor an [ApiException] and so escapes every `on`-clause
  /// the callers wrote.
  static Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } on FormatException {
      throw AuthException(
        'Non-JSON body: ${response.body.length} bytes',
        statusCode: response.statusCode,
        kind: ApiErrorKind.badResponse,
      );
    }
  }

  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw AuthException(
        'Malformed access token',
        kind: ApiErrorKind.badResponse,
      );
    }
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is! Map<String, dynamic>) {
        throw AuthException(
          'Malformed access token',
          kind: ApiErrorKind.badResponse,
        );
      }
      return payload;
    } on FormatException {
      // Covers both base64 and JSON failures in the token payload.
      throw AuthException(
        'Malformed access token',
        kind: ApiErrorKind.badResponse,
      );
    }
  }

  /// Pulls the `refreshToken=...` pair out of the Set-Cookie header so it
  /// can be replayed as a Cookie header later.
  static String? _extractRefreshCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return null;

    final match = RegExp(r'refreshToken=[^;]+').firstMatch(setCookie);
    return match?.group(0);
  }

  static String _extractError(Map<String, dynamic> body) {
    // Validation failures come back as {"errors": {field: message}},
    // everything else as {"message": "..."}. Both are stringified rather than
    // cast: this runs on the failure path, where the body is least trustworthy,
    // and a TypeError here would mask the real error.
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      return errors.values.join('\n');
    }
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    return 'Something went wrong';
  }
}
