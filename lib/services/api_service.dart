import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // Your AuthService to get token

class ApiService {
  static const String baseUrl = "https://vibezone-backend.fly.dev";

  // 🔵 Fetch Profile Data
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final String? token = await AuthService.getToken(); // 🔥 FIXED

    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/'),
        headers: {
          //'Authorization': 'Bearer $token',
          'Authorization': 'Token $token',

        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("⚠️ Failed to fetch profile: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception fetching profile: $e");
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
      debugPrint('❌ Exception while fetching online users: $e');
      return null;
    }
  }

  // 🟩 Accept Incoming Call
  static Future<Map<String, dynamic>?> acceptCall(String otherUser) async {
    final String? token = await AuthService.getToken(); // 🔥 FIXED
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
        return json.decode(response.body);
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
    final String? token = await AuthService.getToken(); // 🔥 FIXED
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/deduct-coins/'),
        headers: {
          //'Authorization': 'Bearer $token',
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
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
    final String? token = await AuthService.getToken(); // 🔥 FIXED
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/end-call/'),
        headers: {
          //'Authorization': 'Bearer $token',
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'username': otherUser}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('⚠️ Error ending call: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception during endCall: $e');
      return null;
    }
  }

  // 🟢 Buy Coins
  static Future<Map<String, dynamic>?> buyCoins(int amount) async {
    final String? token = await AuthService.getToken(); // 🔥 FIXED
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/buy-coins/'),
        headers: {
          //'Authorization': 'Bearer $token',
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'coins': amount}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('⚠️ Error buying coins: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception buying coins: $e');
      return null;
    }
  }

  // 🟣 Check Incoming Call
  static Future<Map<String, dynamic>?> checkIncomingCall() async {
    final String? token = await AuthService.getToken(); // 🔥 FIXED
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/check-incoming-call/'),
        headers: {
          //'Authorization': 'Bearer $token',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('⚠️ Error checking incoming call: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception while checking incoming call: $e');
      return null;
    }
  }

  // 🟡 Toggle Online Status
  static Future<Map<String, dynamic>?> toggleOnlineStatus(bool isOnline) async {
    final String? token = await AuthService.getToken(); // 🔥 FIXED
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://vibezone-backend.fly.dev/api/toggle-online/'),
        headers: {
          //'Authorization': 'Bearer $token',
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'is_online': isOnline}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody != null && responseBody.containsKey('data')) {
          return responseBody['data'];
        } else {
          debugPrint("⚠️ Response does not contain 'data'.");
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('⚠️ Unauthorized, token may have expired.');
        await AuthService.logout(); // 🔥 FIXED
        return null;
      } else {
        debugPrint('⚠️ Error toggling online status: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception toggling online status: $e');
      return null;
    }
  }

  // 🟣 Logout (Optional API call + local logout)
  static Future<void> logout() async {
    final String? token = await AuthService.getToken(); // 🔥 FIXED
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return;
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/api/logout/'),
        headers: {
            
          'Authorization': 'Token $token',
          //'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('❌ Exception during API logout: $e');
    }

    await AuthService.logout(); // 🔥 FIXED
  }
}
