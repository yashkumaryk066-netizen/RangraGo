import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
        final token = data['token'];
        final user = data['user'];
        AppConfig.userToken = token;
        
        // Persist session to match main.dart logic
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_data', jsonEncode(user));
        await prefs.setBool('is_driver', role == "DRIVER");
        
        print("✅ Login Success: Session Persisted");
        return data;
      } else {
        print("❌ Auth Error (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      print("🚨 Network/Server Error: $e");
      return null;
    }
  }

  Future<void> logout() async {
    AppConfig.userToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("👋 Logged out and session cleared");
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      AppConfig.userToken = token;
      print("🔄 Auto-login successful with persisted token");
      return true;
    }
    return false;
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

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse("${AppConfig.authUrl}/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AppConfig.userToken}"
      },
      body: jsonEncode(updates),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'];
    }
    return null;
  }
}

