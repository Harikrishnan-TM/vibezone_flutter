import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import 'call_screen.dart'; // <--- Needed for navigating to CallScreen
import 'package:http/http.dart' as http; // <--- Needed to send POST to backend

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
    _connectWebSocket();
  }

  void _loadUsers() async {
    try {
      List<dynamic>? users = await ApiService.fetchOnlineUsers();
      if (users != null) {
        setState(() {
          onlineUsers = users;
        });
      }
    } catch (e) {
      print('Failed to load users: $e');
    }
  }

  void _connectWebSocket() {
    _socketService = SocketService(
      onIncomingCall: () {
        setState(() {
          incomingCall = true;
        });
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushNamed(context, '/call');
        });
      },
      onRefreshUsers: (List<dynamic> newUsers) {
        setState(() {
          onlineUsers = newUsers..shuffle();
        });
      },
    );
    _socketService.connect();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  void _handleLogout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _initiateCall(String username) async {
    try {
      final response = await http.post(
        Uri.parse('http://your_backend_url/api/call/$username/'), // <-- Update backend URL here
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${await AuthService.getToken()}',
        },
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              otherUser: username,
              walletCoins: 100, // You can pass real coins dynamically if needed
              isInitiator: true,
            ),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? 'Failed to initiate call')),
        );
      }
    } catch (e) {
      print('Call error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error')),
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
                // Top Bar
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
                            // navigate to buy coins page
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
                // Horizontal scroll list
                Expanded(
                  child: ListView.builder(
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
                          boxShadow: [
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
                              onPressed: () {
                                _initiateCall(user['username']); // 👈 UPDATED here
                              },
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
                  children: [
                    const Text(
                      '📞 Incoming Call...',
                      style: TextStyle(color: Colors.white, fontSize: 28),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
