import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // API endpoints
  final String _loginUrl = 'https://vibezone-backend.fly.dev/api/login/';
  final String _signupUrl = 'https://vibezone-backend.fly.dev/api/signup/';
  static const String _confirmPaymentUrl =
      'https://vibezone-backend.fly.dev/confirm-payment/';
  static const String _walletBalanceUrl =
      'https://vibezone-backend.fly.dev/api/get-wallet-balance/';

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
        await saveUsername(data['username']);
        print('✅ Login successful: Token and username saved.');
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
  Future<String> signupUser(
      String username, String email, String password, bool isGirl) async {
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
        await saveUsername(data['username']);
        print('✅ Signup successful: Token and username saved.');
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

  // ✅ Confirm Payment (no token required anymore)
  static Future<bool> confirmPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String amount,
  }) async {
    try {
      final username = await getUsername();

      if (username == null) {
        print('❌ Username is null, cannot confirm payment.');
        return false;
      }

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> payload = {
        'payment_id': paymentId,
        'order_id': orderId,
        'signature': signature,
        'amount': amount,
        'username': username,
      };

      print('📦 Sending confirm-payment request...');
      print('👤 Username: $username');
      print('🧾 Headers: $headers');
      print('📤 Payload: $payload');

      final response = await http.post(
        Uri.parse(_confirmPaymentUrl),
        headers: headers,
        body: jsonEncode(payload),
      );

      print('📬 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Payment confirmation successful');
        return true;
      } else {
        print('❌ Payment confirmation failed (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception during payment confirmation: $e');
      return false;
    }
  }

  // 💰 ✅ Fetch Wallet Balance directly from API
  static Future<Map<String, dynamic>?> fetchWalletBalance() async {
    final token = await getToken();

    if (token == null) {
      print('❌ Cannot fetch wallet: No token found.');
      return null;
    }

    final Uri url = Uri.parse(_walletBalanceUrl);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        print('✅ Wallet fetched: ${json['data']}');
        return json['data']; // Includes keys like 'balance', 'earnings_coins', etc.
      } else {
        print('❌ Failed to fetch wallet balance: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error fetching wallet balance: $e');
      return null;
    }
  }

  // 🧾 Save token
  static Future<void> saveToken(String token) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('🔐 Token saved in SharedPreferences');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  // 👤 Save username
  static Future<void> saveUsername(String username) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      print('👤 Username saved in SharedPreferences');
    } catch (e) {
      print('❌ Error saving username: $e');
    }
  }

  // 📤 Retrieve token
  static Future<String?> getToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('❌ Error retrieving token: $e');
      return null;
    }
  }

  // 📤 Retrieve username
  static Future<String?> getUsername() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('username');
    } catch (e) {
      print('❌ Error retrieving username: $e');
      return null;
    }
  }

  // 🗑 Logout user
  static Future<void> logout() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('username');
      print('🚫 Token and username removed from SharedPreferences');
    } catch (e) {
      print('❌ Error removing credentials: $e');
    }
  }

  // 🔍 Check login status
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
