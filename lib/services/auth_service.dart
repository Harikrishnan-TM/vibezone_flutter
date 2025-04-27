import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // API endpoints
  final String _loginUrl = 'https://vibezone-backend.fly.dev/api/login/';
  final String _signupUrl = 'https://vibezone-backend.fly.dev/api/signup/';

  // 🔐 Login User
  Future<String> loginUser(String username, String password) async {
    final Uri url = Uri.parse(_loginUrl);

    try {
      final http.Response response = await http.post(url, body: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        await saveToken(data['token']);
        print('✅ Login successful: Token saved.');
        return 'success';
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        print('❌ Login failed: ${errorData['message']}');
        return errorData['message'] ?? 'Unknown error occurred.';
      }
    } catch (e) {
      print('⚠️ Login error: $e');
      return 'An error occurred: $e';
    }
  }

  // 📝 Signup User
  Future<String> signupUser(String username, String email, String password, bool isGirl) async {
    final Uri url = Uri.parse(_signupUrl);

    try {
      final http.Response response = await http.post(url, body: {
        'username': username,
        'email': email,
        'password': password,
        'is_girl': isGirl.toString(),
      });

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        await saveToken(data['token']);
        print('✅ Signup successful: Token saved.');
        return 'success';
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        print('❌ Signup failed: ${errorData['message']}');
        return errorData['message'] ?? 'Unknown error occurred.';
      }
    } catch (e) {
      print('⚠️ Signup error: $e');
      return 'An error occurred: $e';
    }
  }

  // 💾 Save token locally
  static Future<void> saveToken(String token) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('🔐 Token saved in SharedPreferences');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  // 📤 Retrieve token
  static Future<String?> getToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      print('📥 Retrieved token: $token');
      return token;
    } catch (e) {
      print('❌ Error retrieving token: $e');
      return null;
    }
  }

  // 🗑 Remove token (logout)
  static Future<void> logout() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('🚫 Token removed');
    } catch (e) {
      print('❌ Error removing token: $e');
    }
  }

  // ✅ Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
