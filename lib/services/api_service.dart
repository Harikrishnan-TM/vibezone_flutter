import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // Your AuthService to get token

class ApiService {
  static const String baseUrl = "https://vibezone-backend.fly.dev";

  // 🔵 Fetch Profile Data
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final String? token = await AuthService().getToken(); // Get the token

    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null; // If there's no token, return null
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token', // Include the token in headers
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return the profile data if successful
      } else {
        debugPrint("⚠️ Failed to fetch profile: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception fetching profile: $e");
      return null; // Return null if an exception occurs
    }
  }

  // 🟠 Fetch Online Users
  static Future<List<dynamic>?> fetchOnlineUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/online-users/'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("⚠️ Error fetching online users - Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching users: $e');
      return null;
    }
  }

  // 🟩 Accept Incoming Call
  static Future<Map<String, dynamic>?> acceptCall(String otherUser) async {
    final String? token = await AuthService().getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/accept-call/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'username': otherUser}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Return the response if successful
      } else {
        debugPrint('⚠️ Error accepting call: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception accepting call: $e');
      return null;
    }
  }

  // 🟩 Deduct Coins During Call
  static Future<Map<String, dynamic>?> deductCoins() async {
    final String? token = await AuthService().getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/deduct-coins/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Return the updated coins and status
      } else {
        debugPrint('⚠️ Error deducting coins: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception during deductCoins: $e');
      return null;
    }
  }

  // 🟩 End Call
  static Future<Map<String, dynamic>?> endCall(String otherUser) async {
    final String? token = await AuthService().getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/end-call/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'username': otherUser}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Return the response indicating call has ended
      } else {
        debugPrint('⚠️ Error ending call: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception during endCall: $e');
      return null;
    }
  }
}
