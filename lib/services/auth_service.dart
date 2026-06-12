import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

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

  /// Logs in with phone + password and stores the session.
  ///
  /// The backend puts the role inside the JWT payload (not in the user
  /// object of the response), so it is read by decoding the access token.
  static Future<AuthUser> login(String phone, String password) async {
    final uri = Uri.parse('$_baseUrl/v1/auth/login');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(
        _extractError(body),
        statusCode: response.statusCode,
      );
    }

    final accessToken = body['accessToken'] as String;
    final payload = _decodeJwtPayload(accessToken);
    final userJson = body['user'] as Map<String, dynamic>;

    final user = AuthUser(
      id: userJson['id'] as int,
      name: userJson['name'] as String,
      phone: userJson['phone'] as String,
      role: (payload['role'] ?? '') as String,
    );

    final session = AuthSession.instance;
    session.accessToken = accessToken;
    session.refreshTokenCookie = _extractRefreshCookie(response);
    session.user = user;

    return user;
  }

  /// Exchanges the stored refresh-token cookie for a new access token.
  static Future<void> refresh() async {
    final session = AuthSession.instance;
    final cookie = session.refreshTokenCookie;
    if (cookie == null) {
      throw AuthException('No refresh token available', statusCode: 401);
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/v1/auth/refresh'),
      headers: {'Cookie': cookie},
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AuthException(
        _extractError(body),
        statusCode: response.statusCode,
      );
    }

    session.accessToken = body['accessToken'] as String;
  }

  /// Revokes the refresh token server-side and clears the local session.
  static Future<void> logout() async {
    final session = AuthSession.instance;
    final cookie = session.refreshTokenCookie;

    try {
      await http.post(
        Uri.parse('$_baseUrl/v1/auth/logout'),
        headers: {'Cookie': ?cookie},
      );
    } finally {
      session.clear();
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

  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw AuthException('Malformed access token');
    }
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
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
    // everything else as {"message": "..."}.
    final errors = body['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      return errors.values.join('\n');
    }
    return (body['message'] ?? 'Something went wrong') as String;
  }
}
