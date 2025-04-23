import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ For debugPrint
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://vibezone-backend.fly.dev";

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
}
