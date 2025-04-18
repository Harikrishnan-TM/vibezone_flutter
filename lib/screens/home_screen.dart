import 'package:flutter/material.dart';
import '../services/api_service.dart';  // adjust path if needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String message = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  void _loadMessage() async {
    String? response = await ApiService.fetchHello(); // ✅ Correct method name
    setState(() {
      message = response ?? "Failed to load message";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hello from Backend")),
      body: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
