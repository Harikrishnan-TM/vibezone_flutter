import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import 'call_screen.dart';
import 'HomeContent.dart';
import 'package:http/http.dart' as http;
import '../main.dart'; // Make sure this imports the file where `routeObserver` is declared.

class HomeScreen extends StatefulWidget {
  final double? walletBalance;

  const HomeScreen({
    Key? key,
    this.walletBalance,
  }) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  List<dynamic> onlineUsers = [];
  bool incomingCall = false;
  int walletCoins = 0;
  double? walletBalance;
  late SocketService _socketService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    walletBalance = widget.walletBalance;
    _checkAndLoadUsers();
    _loadWalletCoins();
    _loadWalletBalance();
    _connectWebSocket();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    //routeObserver.subscribe(this, ModalRoute.of(context)!);
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute<dynamic>);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _socketService.disconnect();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when user navigates back to this screen
    _loadWalletCoins();
    _loadWalletBalance();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWalletCoins();
      _loadWalletBalance();
    }
  }

  void _checkAndLoadUsers() async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      _loadUsers(token);
    }
  }

  void _loadUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://vibezone-backend.fly.dev/api/online-users/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            onlineUsers = users['online_users'];
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Exception in _loadUsers: $e');
    }
  }

  void _loadWalletCoins() async {
    try {
      final profile = await ApiService.fetchProfile();
      if (mounted && profile != null) {
        setState(() {
          walletCoins = profile['home_page_coins'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading wallet coins: $e');
    }
  }

  void _loadWalletBalance() async {
    try {
      final balanceData = await ApiService.fetchWalletBalance();
      if (mounted) {
        setState(() {
          walletBalance = balanceData;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading wallet balance: $e');
    }
  }

  void refreshWalletCoins() {
    _loadWalletCoins();
    _loadWalletBalance();
  }

  void _connectWebSocket() {
    _socketService = SocketService.getInstance();

    _socketService.registerCallbacks(
      onIncomingCall: () {
        if (mounted) {
          setState(() {
            incomingCall = true;
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushNamed(context, '/call');
            }
          });
        }
      },
      onRefreshUsers: (List<dynamic> newUsers) {
        if (mounted) {
          setState(() {
            onlineUsers = newUsers..shuffle();
          });
        }
      },
    );

    _socketService.connect();
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _initiateCall(String username) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in. Please log in first.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://vibezone-backend.fly.dev/api/call/$username/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              otherUser: username,
              walletCoins: walletCoins,
              isInitiator: true,
            ),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? 'Failed to initiate call')),
        );
      }
    } catch (e) {
      debugPrint('❌ Call error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hello from Backend"),
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          HomeContent(
            onlineUsers: onlineUsers,
            walletCoins: walletCoins,
            walletBalance: walletBalance,
            onUsersUpdated: (newUsers) {
              setState(() {
                onlineUsers = newUsers;
              });
            },
            onCall: _initiateCall,
            onRefreshWallet: refreshWalletCoins,
          ),
          if (incomingCall)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '📞 Incoming Call...',
                      style: TextStyle(color: Colors.white, fontSize: 28),
                    ),
                    SizedBox(height: 20),
                    CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
