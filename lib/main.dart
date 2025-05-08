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

  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded successfully.");
  } catch (e) {
    debugPrint("❌ Failed to load .env: $e");
  }

  SocketService.getInstance().connect();

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
  late String _deepLinkMessage = "Waiting for deep link...";

  @override
  void initState() {
    super.initState();
    _handleInitialDeepLink();
    _initUniLinks();
  }

  Future<void> _handleInitialDeepLink() async {
    try {
      final link = await getInitialLink();
      if (link != null) {
        _handleDeepLink(link);
      }
    } catch (e) {
      debugPrint("❌ Error retrieving initial link: $e");
    }
  }

  Future<void> _initUniLinks() async {
    try {
      linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      });
    } catch (e) {
      debugPrint("Error listening to deep links: $e");
    }
  }

  void _handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);

      if (uri.host == "vibezone-backend.fly.dev" &&
          uri.path == "/confirm-web-payment") {
        final paymentId = uri.queryParameters['payment_id'];
        final orderId = uri.queryParameters['order_id'];
        final signature = uri.queryParameters['signature'];

        if (paymentId != null && orderId != null && signature != null) {
          _confirmPayment(paymentId, orderId, signature);
        } else {
          debugPrint("❌ Missing payment params in deep link.");
        }
      }
    } catch (e) {
      debugPrint("❌ Error parsing deep link: $e");
    }
  }

  Future<void> _confirmPayment(String paymentId, String orderId, String signature) async {
    try {
      final success = await AuthService.confirmPayment(paymentId, orderId, signature);
      if (success) {
        setState(() {
          _deepLinkMessage = "✅ Payment successful. Redirecting...";
        });
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _deepLinkMessage = "❌ Payment failed. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _deepLinkMessage = "❌ Error confirming payment: $e";
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
        '/buy-coins': (context) => const CoinPurchasePage(),
        '/win-money': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return WinMoneyPage(
            initialEarningCoins: args['initialEarningCoins'] ?? 0,
          );
        },
        '/kyc': (context) => const KycScreen(),
      },
      home: Scaffold(
        body: Center(
          child: Text(_deepLinkMessage),
        ),
      ),
    );
  }
}