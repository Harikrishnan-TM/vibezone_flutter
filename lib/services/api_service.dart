import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ For debugPrint
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // ✅ Your AuthService to get token

class ApiService {
  static const String baseUrl = "https://vibezone-backend.fly.dev";

  // 🔵 Fetch Hello
  static Future<String?> fetchHello() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/api/hello/"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)["message"];
      } else {
        debugPrint("⚠️ API error - Status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception in fetchHello: $e");
      return null;
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

  // 🟩 Check Incoming Call
  static Future<bool> checkIncomingCall() async {
    final String? token = await AuthService().getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/check-incoming-call/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['being_called'] ?? false;
      } else {
        debugPrint('⚠️ Check incoming call failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception checking incoming call: $e');
      return false;
    }
  }

  // 🟩 Buy Coins
  static Future<Map<String, dynamic>?> buyCoins(int coins) async {
    final String? token = await AuthService().getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/buy-coins/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'coins': coins}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('⚠️ Failed to buy coins: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception during buyCoins: $e');
      return null;
    }
  }
}



// 🟦 Check if User is in a Call
static Future<bool> checkCallStatus() async {
  final String? token = await AuthService().getToken();
  if (token == null) {
    debugPrint('❌ No auth token found.');
    return false;
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/check-call-status/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['in_call'] ?? false;
    } else {
      debugPrint('⚠️ Failed to check call status: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('❌ Exception checking call status: $e');
    return false;
  }
}
