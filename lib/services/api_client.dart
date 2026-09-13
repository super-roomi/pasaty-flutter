import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

/// What went wrong, in terms the UI can localize.
///
/// The backend replies with free-form English prose and no error codes
/// (`"Invalid routeid"`, `"No routes founded"`, `"Insuffecient Data"`), so its
/// text can never be shown to an Arabic-speaking parent. Callers switch on
/// this instead and look the wording up in the ARB files.
enum ApiErrorKind {
  /// The request never completed — no signal, DNS failure, server unreachable.
  network,

  /// A response arrived but was not the JSON we expected (proxy error page,
  /// captive portal, truncated body, missing required field).
  badResponse,

  /// 401 — the session is gone.
  unauthorized,

  /// 403 — authenticated, but not allowed to do this.
  forbidden,

  /// 404.
  notFound,

  /// 409 — valid request, wrong moment (e.g. the afternoon run cannot start
  /// until the morning one is finished).
  conflict,

  /// 5xx.
  server,

  unknown,
}

/// Maps an HTTP status onto the kind the UI localizes from.
ApiErrorKind kindForStatus(int? status) {
  if (status == null) return ApiErrorKind.unknown;
  if (status == 401) return ApiErrorKind.unauthorized;
  if (status == 403) return ApiErrorKind.forbidden;
  if (status == 404) return ApiErrorKind.notFound;
  if (status == 409) return ApiErrorKind.conflict;
  if (status >= 500) return ApiErrorKind.server;
  return ApiErrorKind.unknown;
}

/// Error from an authenticated API call.
///
/// [message] is the backend's own English text: useful in logs and in debug
/// builds, never appropriate as user-facing copy. Localize from [kind]
/// instead — see `errorText` in `lib/Util/error_text.dart`.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorKind kind;

  ApiException(this.message, {this.statusCode, ApiErrorKind? kind})
    : kind = kind ?? kindForStatus(statusCode);

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

  /// Injectable for tests; see [resetForTesting].
  static http.Client client = http.Client();

  @visibleForTesting
  static void resetForTesting({http.Client? withClient}) {
    client = withClient ?? http.Client();
  }

  static Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('POST', path, body: body);

  static Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('PATCH', path, body: body);

  /// DELETE, optionally with a body.
  ///
  /// Unusual but deliberate: the absence and device-token endpoints identify
  /// what to remove by a composite key rather than a path id, and the backend
  /// reads it from the body.
  static Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('DELETE', path, body: body);

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

    final map = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(map), statusCode: response.statusCode);
    }
    return map;
  }

  /// Decodes a body that is *supposed* to be JSON.
  ///
  /// A reverse-proxy 502, a captive portal, or a 204 returns HTML or an empty
  /// string. A bare `jsonDecode` throws [FormatException], which is not an
  /// [ApiException] — so it escaped before the status check below and the
  /// caller never learned the HTTP status.
  static Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } on FormatException {
      throw ApiException(
        'Non-JSON body: ${response.body.length} bytes',
        statusCode: response.statusCode,
        kind: ApiErrorKind.badResponse,
      );
    }
  }

  /// Stringified, not cast: this runs on the failure path where the body is
  /// least trustworthy, and a TypeError here would mask the real error.
  static String _errorMessage(Map<String, dynamic> map) {
    final errors = map['errors'];
    if (errors is Map && errors.isNotEmpty) return errors.values.join('\n');
    final message = map['message'];
    if (message is String && message.isNotEmpty) return message;
    return 'Request failed';
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
      'GET' => client.get(uri, headers: headers),
      'POST' => client.post(uri, headers: headers, body: encoded),
      'PATCH' => client.patch(uri, headers: headers, body: encoded),
      'DELETE' => client.delete(uri, headers: headers, body: encoded),
      _ => throw ArgumentError('Unsupported method $method'),
    };
  }
}
