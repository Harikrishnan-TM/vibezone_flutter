import 'package:flutter/material.dart';
import '../services/api_service.dart'; // adjust path if needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? message;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hello from Backend")),
      body: Center(
        child: message == null
            ? const CircularProgressIndicator() // loading spinner
            : Text(
                message!,
                style: const TextStyle(fontSize: 20),
              ),
      ),
    );
  }
}
