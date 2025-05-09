import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vibezone_flutter/services/auth_service.dart';
import 'package:vibezone_flutter/services/socket_service.dart';
import 'package:vibezone_flutter/screens/login_screen.dart';
import 'package:vibezone_flutter/screens/signup_screen.dart';
import 'package:vibezone_flutter/screens/home_screen.dart';
import 'package:vibezone_flutter/screens/profile_screen.dart';
import 'package:vibezone_flutter/screens/call_screen.dart';
import 'package:vibezone_flutter/screens/buy_coins_screen.dart';
import 'package:vibezone_flutter/screens/coin_purchase_page.dart';
import 'package:vibezone_flutter/screens/win_money_page.dart';
import 'package:vibezone_flutter/screens/withdraw_status_screen.dart';
import 'package:vibezone_flutter/screens/kyc_screen.dart';
import 'package:vibezone_flutter/main_container.dart';

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
        _routeToDeepLinkTarget(link);
      }
    } catch (e) {
      debugPrint("❌ Error retrieving initial link: $e");
    }
  }

  void _initUniLinks() {
    linkStream.listen((String? link) {
      if (link != null) {
        _routeToDeepLinkTarget(link);
      }
    }, onError: (err) {
      debugPrint("❌ Deep link stream error: $err");
    });
  }

  void _routeToDeepLinkTarget(String link) {
    try {
      final uri = Uri.parse(link);

      if (uri.scheme == "myapp" && uri.host == "payment-success") {
        // Let CoinPurchasePage handle this deep link as it already does
        // Optionally navigate to CoinPurchasePage if not already there
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/buy-coins');
        });
      }
    } catch (e) {
      debugPrint("❌ Error routing deep link: $e");
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
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return WinMoneyPage(
            initialEarningCoins: args['initialEarningCoins'] ?? 0,
          );
        },
        '/kyc': (context) => const KycScreen(),
      },
    );
  }
}
