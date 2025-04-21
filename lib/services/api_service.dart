import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://vibezone-backend.fly.dev"; // ✅ Use PC's local IP

  static Future<String?> fetchHello() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/hello/"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)["message"];
      } else {
        print("Failed to get response: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching hello: $e");
      return null;
    }
  }
}
