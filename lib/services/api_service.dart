import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'auth_service.dart'; // Your AuthService to get token

class ApiService {
  static const String baseUrl = "https://vibezone-backend.fly.dev";
  static const String wsUrl = "wss://vibezone-backend.fly.dev/ws/online-users/";
  static WebSocketChannel? _channel;

  // 🔌 Connect to WebSocket
  static void connectToWebSocket({
    required Function onIncomingCall,
    required Function(List<dynamic>) onRefreshUsers,
  }) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen((event) {
        final data = json.decode(event);
        debugPrint("📡 WS Message: $data");

        if (data['type'] == 'call') {
          onIncomingCall();
        } else if (data['type'] == 'refresh') {
          onRefreshUsers(data['payload']['users']);
        }
      }, onError: (error) {
        debugPrint('❌ WebSocket error: $error');
      }, onDone: () {
        debugPrint('🛑 WebSocket closed.');
      });
    } catch (e) {
      debugPrint('❌ Failed to connect to WebSocket: $e');
    }
  }

  // ❌ Disconnect WebSocket
  static void disconnectFromWebSocket() {
    _channel?.sink.close();
    _channel = null;
    debugPrint('🔌 WebSocket disconnected');
  }

  // 🔵 Fetch Profile Data
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final String? token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/'),
        headers: {'Authorization': 'Token $token'},
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

  // ✅ NEW: Get Current Username
  static Future<String?> getCurrentUsername() async {
    final profile = await fetchProfile();
    return profile?['username'];
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
    final String? token = await AuthService.getToken();
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
    final String? token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/deduct-coins/'),
        headers: {
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
    final String? token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/end-call/'),
        headers: {
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
    final String? token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/buy-coins/'),
        headers: {
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
    final String? token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/check-incoming-call/'),
        headers: {
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
    final String? token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/toggle-online/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'is_online': isOnline}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return responseBody['data'];
      } else if (response.statusCode == 401) {
        debugPrint('⚠️ Unauthorized, token may have expired.');
        await AuthService.logout();
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

  // 🟣 Logout (API + Local)
  static Future<void> logout() async {
    final String? token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ No auth token found.');
      return;
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/api/logout/'),
        headers: {'Authorization': 'Token $token'},
      );
    } catch (e) {
      debugPrint('❌ Exception during API logout: $e');
    }

    await AuthService.logout(); // Local cleanup
  }

  // 🔵 Upload KYC
  static Future<Map<String, dynamic>> uploadKyc({
    required String realName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required File panCardFile,
    required String authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload-kyc/');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $authToken';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = realName;
      request.fields['bank_name'] = bankName;
      request.fields['account_number'] = accountNumber;
      request.fields['ifsc_code'] = ifscCode;

      final mimeType = lookupMimeType(panCardFile.path) ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);

      final panCardImage = await http.MultipartFile.fromPath(
        'pan_card_image',
        panCardFile.path,
        contentType: mediaType,
      );
      request.files.add(panCardImage);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'KYC submitted successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to submit KYC',
          'errors': jsonDecode(responseBody),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // ✅ Set User in_call_with Status
  static Future<void> setUserInCallWith(String username) async {
    final String? token = await AuthService.getToken();
    if (token == null) {
      debugPrint('❌ No auth token found for setting in_call_with');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/set-in-call-with/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'in_call_with': username}),
      );

      if (response.statusCode != 200) {
        debugPrint('⚠️ Failed to update in_call_with: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error setting in_call_with: $e');
    }
  }
}
