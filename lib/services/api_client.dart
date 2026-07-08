import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

/// Error from an authenticated API call. Carries the backend's
/// {message: ...} text and the HTTP status so UI can branch on 403/409.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Shared HTTP layer for authenticated /v1/* calls.
///
/// Every request sends the Bearer token; on 401/403 the access token is
/// refreshed once and the request retried (same contract the backend's
/// authMiddleware expects).
class ApiClient {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> get(String path) =>
      _send('GET', path);

  static Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  static Future<Map<String, dynamic>> patch(String path,
          {Map<String, dynamic>? body}) =>
      _send('PATCH', path, body: body);

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    var response = await _raw(method, path, body);

    if (response.statusCode == 401 || response.statusCode == 403) {
      // Could be an expired access token — refresh once and retry. A real
      // role/ownership 403 will just fail again and surface below.
      try {
        await AuthService.refresh();
        response = await _raw(method, path, body);
      } on AuthException {
        // Refresh itself failed: fall through with the original response.
      }
    }

    final decoded = jsonDecode(response.body);
    final map = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        (map['message'] ?? 'Request failed') as String,
        statusCode: response.statusCode,
      );
    }
    return map;
  }

  static Future<http.Response> _raw(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = AuthService.authHeaders();
    final encoded = body == null ? null : jsonEncode(body);

    return switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri, headers: headers, body: encoded),
      'PATCH' => http.patch(uri, headers: headers, body: encoded),
      _ => throw ArgumentError('Unsupported method $method'),
    };
  }
}
