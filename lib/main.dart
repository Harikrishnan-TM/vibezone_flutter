import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibezone_flutter/services/auth_service.dart';
import 'package:vibezone_flutter/screens/login_screen.dart';
import 'package:vibezone_flutter/screens/signup_screen.dart';
import 'package:vibezone_flutter/screens/home_screen.dart';
import 'package:vibezone_flutter/screens/profile_screen.dart';
import 'package:vibezone_flutter/screens/call_screen.dart';
import 'package:vibezone_flutter/screens/buy_coins_screen.dart';
import 'package:vibezone_flutter/services/socket_service.dart';
import 'package:vibezone_flutter/screens/win_money_page.dart';
import 'package:vibezone_flutter/screens/withdraw_status_screen.dart';
import 'package:vibezone_flutter/main_container.dart';
import 'package:vibezone_flutter/screens/kyc_screen.dart';
import 'package:vibezone_flutter/screens/coin_purchase_page.dart';
import 'package:uni_links/uni_links.dart';  // Import uni_links package

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
  SocketService.getInstance().connect();

  // Check login status
  final bool isLoggedIn = await AuthService.isLoggedIn();

  runApp(VibezoneApp(isLoggedIn: isLoggedIn));
}

class VibezoneApp extends StatefulWidget {
  final bool isLoggedIn;

  const VibezoneApp({super.key, required this.isLoggedIn});

  @override
  State<VibezoneApp> createState() => _VibezoneAppState();
}

class _VibezoneAppState extends State<VibezoneApp> {
  late Uri _initialLink;
  late String _deepLinkMessage;

  @override
  void initState() {
    super.initState();

    _deepLinkMessage = "Waiting for deep link...";

    // Handle initial deep link (when the app is launched with a deep link)
    _handleDeepLink();

    // Listen for future deep links (when app is already running)
    _initUniLinks();
  }

  // Initialize uni_links and handle incoming deep links
  Future<void> _initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      });
    } catch (e) {
      debugPrint("Error handling deep link: $e");
    }
  }

  // Handle the deep link and navigate to the correct page
  void _handleDeepLink([String? link = ""]) {
    Uri uri = Uri.parse(link ?? _initialLink.toString());

    if (uri.host == "vibezone-backend.fly.dev" && uri.path == "/confirm-web-payment") {
      final paymentId = uri.queryParameters['payment_id'];
      final orderId = uri.queryParameters['order_id'];
      final signature = uri.queryParameters['signature'];

      if (paymentId != null && orderId != null && signature != null) {
        // Here you can confirm payment or navigate to the home page
        _confirmPayment(paymentId, orderId, signature);
      }
    }
  }

  // Simulate payment confirmation and redirect to the home page
  Future<void> _confirmPayment(String paymentId, String orderId, String signature) async {
    try {
      // You would usually call your backend here to confirm the payment
      final success = await AuthService.confirmPayment(paymentId, orderId, signature);

      if (success) {
        setState(() {
          _deepLinkMessage = "Payment successful, redirecting to Home page...";
        });

        // Redirect to the Home page after successful payment
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _deepLinkMessage = "Payment failed. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _deepLinkMessage = "Error confirming payment: $e";
      });
    }
  }

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
      initialRoute: widget.isLoggedIn ? '/home' : '/login',
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
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainContainer(),
        '/profile': (context) => const ProfileScreen(),
        '/withdraw-status': (context) => const WithdrawStatusScreen(),
        '/buy-coins': (context) => const CoinPurchasePage(), // <-- This is the key
        '/win-money': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return WinMoneyPage(
            initialEarningCoins: args['initialEarningCoins'] ?? 0,
          );
        },
        '/kyc': (context) => const KycScreen(), // ✅ <-- Add this line
      },
      home: Scaffold(
        body: Center(
          child: Text(_deepLinkMessage), // Show deep link status
        ),
      ),
    );
  }
}
