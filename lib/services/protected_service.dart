import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

/// Profile returned by GET /v1/protected/profile.
class Profile {
  final int id;
  final String name;
  final String phone;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.name,
    required this.phone,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      createdAt: json['createdat'] != null
          ? DateTime.tryParse(json['createdat'].toString())
          : null,
    );
  }
}

/// Client for the /v1/protected/* routes, which require a Bearer token.
class ProtectedService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<Profile> getProfile() async {
    final response = await _authorizedGet('/v1/protected/profile');
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(
        (body['message'] ?? 'Request failed') as String,
        statusCode: response.statusCode,
      );
    }

    return Profile.fromJson(body['user'] as Map<String, dynamic>);
  }

  /// GET with the stored access token; if the token is rejected (the
  /// backend answers 401/403 for expired or invalid tokens), refresh it
  /// once and retry.
  static Future<http.Response> _authorizedGet(String path) async {
    final uri = Uri.parse('$_baseUrl$path');

    var response = await http.get(uri, headers: AuthService.authHeaders());
    if (response.statusCode == 401 || response.statusCode == 403) {
      await AuthService.refresh();
      response = await http.get(uri, headers: AuthService.authHeaders());
    }
    return response;
  }
}
