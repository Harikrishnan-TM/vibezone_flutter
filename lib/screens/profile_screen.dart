import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; // Import AuthService

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  // Fetch the user's profile data
  Future<void> _fetchProfileData() async {
    final profile = await ApiService.fetchProfile();
    if (profile != null && profile['success'] == true && profile['data'] != null) {
      setState(() {
        username = profile['data']['username'] ?? '';  // Access 'data' field
        walletCoins = profile['data']['coins'] ?? 0;  // Access 'data' field for coins
        isGirl = profile['data']['is_girl'] ?? false;  // Access 'data' field for 'is_girl'
        isOnline = profile['data']['is_online'] ?? false;  // Access 'data' field for 'is_online'
      });
    }
  }

  // Periodically check for incoming calls
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

  // Toggle online status of the user
  Future<void> _toggleOnlineStatus() async {
    final response = await ApiService.toggleOnlineStatus(!isOnline);
    
    // Check if the response is valid and contains the required data
    if (response != null && response['success'] == true) {
      setState(() {
        isOnline = response['data']['is_online']; // Use the 'is_online' from the API response
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
                      onPressed: () async {
                        await AuthService.logout();
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
