import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibezone_flutter/services/auth_service.dart';
import 'package:vibezone_flutter/screens/login_screen.dart';
import 'package:vibezone_flutter/screens/signup_screen.dart';
import 'package:vibezone_flutter/screens/home_screen.dart';
import 'package:vibezone_flutter/screens/profile_screen.dart';
import 'package:vibezone_flutter/screens/call_screen.dart';
import 'package:vibezone_flutter/screens/buy_coins_screen.dart';
import 'package:vibezone_flutter/services/socket_service.dart'; // ✅ Added for socket singleton
import 'package:vibezone_flutter/screens/win_money_page.dart';
import 'package:vibezone_flutter/screens/withdraw_status_screen.dart';
import 'package:vibezone_flutter/main_container.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded successfully.");
  } catch (e) {
    debugPrint("❌ Failed to load .env: $e");
  }

  // Optionally connect WebSocket globally
  SocketService.getInstance().connect(); // ✅ Optional global socket connection

  // Check login status
  final bool isLoggedIn = await AuthService.isLoggedIn();

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
      onGenerateRoute: (settings) {
        if (settings.name == '/call') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => CallScreen(
              otherUser: args?['otherUser'] ?? 'defaultUser',
              walletCoins: args?['walletCoins'] ?? 100,
              isInitiator: args?['isInitiator'] ?? true,
            ),
          );
        }
        return null; // fallback to routes map
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainContainer(),
        //'/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/buy-coins': (context) => const BuyCoinsScreen(),
        '/withdraw-status': (context) => const WithdrawStatusScreen(),
        '/win-money': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return WinMoneyPage(
            walletCoins: args['walletCoins'],
            isKycCompleted: args['isKycCompleted'],
        );

       },
       
      },

    );
  }
}
