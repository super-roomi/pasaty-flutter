import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator (maps to your machine's localhost)
  // Use your actual IP for a real device, e.g. http://192.168.1.x:3000
  static const String _baseUrl = 'http://127.0.0.1:3000/';

  static Future<String> sendPhoneNumber(String phone) async {
    final uri = Uri.parse('$_baseUrl/api/users/phone');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}), // serialize to JSON
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message']; // whatever your backend returns
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}
