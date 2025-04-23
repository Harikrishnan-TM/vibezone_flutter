import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibezone_flutter/services/auth_service.dart';
import 'package:vibezone_flutter/screens/login_screen.dart';
import 'package:vibezone_flutter/screens/signup_screen.dart';
import 'package:vibezone_flutter/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded successfully.");
  } catch (e) {
    debugPrint("❌ Failed to load .env: $e");
  }

  // Check login status
  final isLoggedIn = await AuthService().isLoggedIn();

  runApp(VibezoneApp(isLoggedIn: isLoggedIn));
}

class VibezoneApp extends StatelessWidget {
  final bool isLoggedIn;

  const VibezoneApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibezone',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
