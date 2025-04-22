import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully.");
  } catch (e) {
    print("❌ Failed to load .env: $e");
  }

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("✅ App reached runApp"),
        ),
      ),
    ),
  );
}


class VibezoneApp extends StatelessWidget {
  const VibezoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibezone',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const HomeScreen(),
    );
  }
}
