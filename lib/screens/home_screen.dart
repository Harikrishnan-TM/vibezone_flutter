import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import 'call_screen.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> onlineUsers = [];
  bool incomingCall = false;
  late SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    // 🔧 Temporarily disabled to test WebSocket causing redirect
    // _connectWebSocket();
  }

  void _loadUsers() async {
    try {
      final token = await AuthService.getToken();
      debugPrint("🔐 Token: $token");

      final response = await http.get(
        Uri.parse('https://vibezone-backend.fly.dev/api/online-users/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("🌐 Status: ${response.statusCode} - Body: ${response.body}");

      if (response.statusCode == 200) {
        final users = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            onlineUsers = users;
          });
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized - redirecting to login');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } else {
        debugPrint('⚠️ Failed to load users: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Exception in _loadUsers: $e');
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

  @override
  void dispose() {
    // Still disconnect safely even if it wasn’t called (no harm)
    _socketService.disconnect();
    super.dispose();
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
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              otherUser: username,
              walletCoins: 100,
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
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('👦'),
                        const SizedBox(width: 8),
                        const Text('🪙 100'),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/buy-coins');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Buy Coins'),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('My Profile'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Online Users 💬",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: onlineUsers.isEmpty
                      ? const Center(child: Text("No users online."))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: onlineUsers.length,
                          itemBuilder: (context, index) {
                            final user = onlineUsers[index];
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.person, size: 40),
                                  Text(
                                    user['username'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _initiateCall(user['username']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    ),
                                    child: const Text(
                                      'Call',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
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
