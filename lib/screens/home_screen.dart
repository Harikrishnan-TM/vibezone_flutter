import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import 'call_screen.dart';
import 'HomeContent.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<dynamic> onlineUsers = [];
  bool incomingCall = false;
  int homePageCoins = 0; // Update to use homePageCoins (for calls)
  late SocketService _socketService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndLoadUsers();
    _loadHomePageCoins();
    _connectWebSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHomePageCoins(); // Refresh home page coins when returning from Buy Coins
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

  // Update: Load home page coins (not wallet coins)
  void _loadHomePageCoins() async {
    try {
      final profile = await ApiService.fetchProfile();
      if (mounted && profile != null) {
        setState(() {
          homePageCoins = profile['home_page_coins'] ?? 0;  // Use home_page_coins field instead
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading home page coins: $e');
    }
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
              walletCoins: homePageCoins, // Use homePageCoins for call
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
      debugPrint('Call error: $e');
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
            walletCoins: homePageCoins, // Pass homePageCoins to HomeContent
            onUsersUpdated: (newUsers) {
              setState(() {
                onlineUsers = newUsers;
              });
            },
            onCall: _initiateCall,
            onRefreshWallet: _loadHomePageCoins,  // Ensure it refreshes coins
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
