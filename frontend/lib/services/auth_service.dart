import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class AuthService {
  Future<Map<String, dynamic>?> loginOrRegister({
    required String email,
    required String name,
    required String role,
    String? googleId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.authUrl}/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "name": name,
          "role": role,
          "googleId": googleId ?? "mock_${email.hashCode}",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppConfig.userToken = data['token'];
        print("Login Success: Token Received");
        return data;
      } else {
        print("Auth Error (${response.statusCode}): ${response.body}");
        return null;
      }

    } catch (e) {
      print("Network Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final response = await http.get(
      Uri.parse("${AppConfig.authUrl}/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AppConfig.userToken}"
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse("${AppConfig.authUrl}/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AppConfig.userToken}"
      },
      body: jsonEncode(updates),
    );
    return response.statusCode == 200;
  }
}

