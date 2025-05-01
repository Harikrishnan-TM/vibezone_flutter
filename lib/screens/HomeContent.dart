import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeContent extends StatefulWidget {
  final List<dynamic> onlineUsers;
  final Function(List<dynamic>) onUsersUpdated;
  final Function(String) onCall;

  const HomeContent({
    Key? key,
    required this.onlineUsers,
    required this.onUsersUpdated,
    required this.onCall,
  }) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Future<void> _refreshUsers() async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      final response = await http.get(
        Uri.parse('https://vibezone-backend.fly.dev/api/online-users/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        final users = jsonDecode(response.body);
        widget.onUsersUpdated(users['online_users']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (coins, buttons)
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
                      onPressed: () => Navigator.pushNamed(context, '/buy-coins'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('Buy Coins'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('My Profile'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Online Users 💬", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: widget.onlineUsers.isEmpty
                  ? const Center(child: Text("No users online."))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.onlineUsers.length,
                      itemBuilder: (context, index) {
                        final user = widget.onlineUsers[index];
                        return SizedBox(
                          width: 100,
                          height: 140, // Fix box height
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.person, size: 40),
                                Text(
                                  user['username'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                ElevatedButton(
                                  onPressed: () => widget.onCall(user['username']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  ),
                                  child: const Text('Call', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
