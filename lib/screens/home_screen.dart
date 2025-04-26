import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart'; // adjust path if needed
import 'login_screen.dart'; // ensure you have this or adjust accordingly
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? message;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  void _loadMessage() async {
    try {
      String? response = await ApiService.fetchHello();
      print("API Response: $response");

      setState(() {
        message = response ?? "Failed to load message";
      });
    } catch (e) {
      print("Caught error in _loadMessage: $e");
      setState(() {
        message = "Exception occurred";
      });
    }
  }

  Future<void> _logout() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      _goToLogin();
      return;
    }

    final response = await http.post(
      Uri.parse('https://your-backend-domain.com/api/logout/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      await storage.delete(key: 'token');
      _goToLogin();
    } else {
      final body = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${body['message']}')),
      );
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hello from Backend"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: Center(
        child: message == null
            ? const CircularProgressIndicator()
            : Text(
                message!,
                style: const TextStyle(fontSize: 20),
              ),
      ),
    );
  }
}
