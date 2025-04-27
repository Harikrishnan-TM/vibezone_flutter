import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // You should create/check ApiService methods for these

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  int walletCoins = 0;
  bool isGirl = false;
  bool isOnline = false;
  bool incomingCallOverlayVisible = false;
  Timer? _callCheckTimer;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _startIncomingCallChecker();
  }

  Future<void> _fetchProfileData() async {
    final profile = await ApiService.fetchProfile();
    if (profile != null) {
      setState(() {
        username = profile['username'] ?? '';
        walletCoins = profile['wallet_coins'] ?? 0;
        isGirl = profile['is_girl'] ?? false;
        isOnline = profile['is_online'] ?? false;
      });
    }
  }

  void _startIncomingCallChecker() {
    _callCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final data = await ApiService.checkIncomingCall();
      if (data != null && data['being_called'] == true && !incomingCallOverlayVisible) {
        setState(() {
          incomingCallOverlayVisible = true;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushNamed(context, '/call');
        }
      }
    });
  }

  Future<void> _toggleOnlineStatus() async {
    final success = await ApiService.toggleOnlineStatus(!isOnline);
    if (success) {
      setState(() {
        isOnline = !isOnline;
      });
    }
  }

  @override
  void dispose() {
    _callCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Text(
                  'Welcome, $username',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your wallet balance: $walletCoins coins',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                if (isGirl) ...[
                  Text(
                    'Status: ${isOnline ? 'Online' : 'Offline'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _toggleOnlineStatus,
                    child: Text(isOnline ? 'Go Offline' : 'Go Online'),
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/buy-coins');
                      },
                      child: const Text('Buy More Coins'),
                    ),
                    const Text('|', style: TextStyle(fontSize: 16)),
                    TextButton(
                      onPressed: () {
                        ApiService.logout(); // Assume you have a logout function
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Incoming call overlay
          if (incomingCallOverlayVisible)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: AnimatedOpacity(
                  opacity: incomingCallOverlayVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: const Text(
                    '📞 Incoming Call...',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
