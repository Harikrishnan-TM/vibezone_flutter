import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibezone_flutter/services/auth_service.dart';
import 'package:vibezone_flutter/screens/login_screen.dart';
import 'package:vibezone_flutter/screens/signup_screen.dart';
import 'package:vibezone_flutter/screens/home_screen.dart';
import 'package:vibezone_flutter/screens/profile_screen.dart'; // ✅
import 'package:vibezone_flutter/screens/call_screen.dart'; // ✅
import 'package:vibezone_flutter/screens/buy_coins_screen.dart'; // ✅

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded successfully.");
  } catch (e) {
    debugPrint("❌ Failed to load .env: $e");
  }

  // Check login status using AuthService
  final bool isLoggedIn = await AuthService.isLoggedIn(); // ✅ Static method call fixed

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/call': (context) => CallScreen(
          otherUser: 'defaultUser', // Pass the required 'otherUser'
          walletCoins: 100, // Provide the walletCoins parameter
        ),
        '/buy-coins': (context) => const BuyCoinsScreen(),
      },
    );
  }
}
