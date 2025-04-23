import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Replace with your API URLs
  final String _loginUrl = 'https://vibezone-backend.fly.dev/api/login/';
  final String _signupUrl = 'https://vibezone-backend.fly.dev/api/signup/';

  // Login User
  Future<String> loginUser(String username, String password) async {
    final url = Uri.parse(_loginUrl);

    try {
      final response = await http.post(url, body: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login Success! Token: ${data['token']}');
        
        // Save token to shared_preferences
        await _saveToken(data['token']);
        return 'success';  // Indicate successful login
      } else {
        final errorData = jsonDecode(response.body);
        print('Login Failed: ${errorData['message']}');
        return errorData['message'] ?? 'Unknown error';  // Return the error message
      }
    } catch (error) {
      print('Error: $error');
      return 'An error occurred: $error';  // Return error message on exception
    }
  }

  // Signup User
  Future<String> signupUser(String username, String email, String password, bool isGirl) async {
    final url = Uri.parse(_signupUrl);

    try {
      final response = await http.post(url, body: {
        'username': username,
        'email': email,
        'password': password,
        'is_girl': isGirl.toString(),
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Signup Success! Token: ${data['token']}');
        
        // Save token to shared_preferences
        await _saveToken(data['token']);
        return 'success';  // Indicate successful signup
      } else {
        final errorData = jsonDecode(response.body);
        print('Signup Failed: ${errorData['message']}');
        return errorData['message'] ?? 'Unknown error';  // Return error message
      }
    } catch (error) {
      print('Error: $error');
      return 'An error occurred: $error';  // Return error message on exception
    }
  }

  // Save token to shared preferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('Token saved successfully!');
  }

  // Get token from shared preferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Retrieved Token: $token');
    return token;
  }

  // Remove token from shared preferences
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('Token removed successfully!');
  }

  // Check if the user is logged in by checking token
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;  // Return true if token exists
  }
}
