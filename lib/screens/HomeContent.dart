import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;

class HomeContent extends StatefulWidget {
  final List<dynamic> onlineUsers;
  final Function(List<dynamic>) onUsersUpdated;
  final Function(String) onCall;
  final int walletCoins;
  final VoidCallback onRefreshWallet;
  final double? walletBalance;

  const HomeContent({
    Key? key,
    required this.onlineUsers,
    required this.onUsersUpdated,
    required this.onCall,
    required this.walletCoins,
    required this.onRefreshWallet,
    this.walletBalance,
  }) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Future<void> _refreshUsers() async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('https://vibezone-backend.fly.dev/api/online-users/'),
          headers: {'Authorization': 'Token $token'},
        );

        if (response.statusCode == 200) {
          final users = jsonDecode(response.body);
          widget.onUsersUpdated(users['online_users']);
        } else {
          debugPrint("❌ Failed to fetch users: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("⚠️ Error fetching users: $e");
      }
    }
  }

  Future<void> _navigateToBuyCoins() async {
    final result = await Navigator.pushNamed(context, '/buy-coins');
    if (result == true) {
      widget.onRefreshWallet(); // Refresh wallet if coins were bought
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
            // Wallet & Coins Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      const Text('👦'),
                      if (widget.walletBalance != null)
                        Text(
                          '₹${widget.walletBalance!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      Text('🪙 ${widget.walletCoins}'),
                      ElevatedButton(
                        onPressed: _navigateToBuyCoins,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Buy Coins'),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
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
                          height: 140,
                          child: Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.person, size: 40),
                                Text(
                                  user['username'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                ElevatedButton(
                                  onPressed: () => widget.onCall(user['username']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
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
