import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'win_money_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  int earningCoins = 0;
  bool isGirl = false;
  bool isOnline = false;
  String kycStatus = 'pending';
  bool incomingCallOverlayVisible = false;
  Timer? _callCheckTimer;
  String? authToken;

  final String baseUrl = 'https://vibezone-backend.fly.dev';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchAll();
    _startIncomingCallChecker();
  }

  Future<void> _loadTokenAndFetchAll() async {
    authToken = await AuthService.getToken();
    if (authToken == null) return;
    await Future.wait([
      _fetchProfileData(),
      _fetchEarningCoins(),
    ]);
  }

  Future<void> _fetchProfileData() async {
    try {
      final profile = await ApiService.fetchProfile();
      if (mounted && profile != null && profile['success'] == true && profile['data'] != null) {
        setState(() {
          username = profile['data']['username'] ?? '';
          isGirl = profile['data']['is_girl'] ?? false;
          isOnline = profile['data']['is_online'] ?? false;
          kycStatus = (profile['data']['kyc_status'] ?? 'pending').toString().toLowerCase();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch profile')),
        );
      }
    }
  }

  Future<void> _fetchEarningCoins() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/get-earnings-wallet/'),
        headers: {'Authorization': 'Token $authToken'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            earningCoins = data['data']?['earnings_coins'] ?? 0;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch earning coins')),
        );
      }
    }
  }

  void _startIncomingCallChecker() {
    _callCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final data = await ApiService.checkIncomingCall();
        if (mounted && data != null && data['being_called'] == true && !incomingCallOverlayVisible) {
          setState(() {
            incomingCallOverlayVisible = true;
          });
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushNamed(context, '/call');
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _toggleOnlineStatus() async {
    try {
      final response = await ApiService.toggleOnlineStatus(!isOnline);
      if (mounted && response != null && response['data'] != null && response['data'].containsKey('is_online')) {
        setState(() {
          isOnline = response['data']['is_online'];
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to toggle status')),
        );
      }
    }
  }

  @override
  void dispose() {
    _callCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKycCompleted = kycStatus == 'completed';

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

                if (isGirl) ...[
                  Text(
                    'Withdrawable Coins: $earningCoins',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'KYC Status: ${kycStatus[0].toUpperCase()}${kycStatus.substring(1)}',
                    style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WinMoneyPage(
                            initialEarningCoins: earningCoins,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text('Win Money 💰'),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Status: ${isOnline ? 'Online' : 'Offline'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _toggleOnlineStatus();
                      await _fetchProfileData(); // Refresh UI
                    },
                    child: Text(isOnline ? 'Go Offline' : 'Go Online'),
                  ),
                  const SizedBox(height: 30),
                ],

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
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Incoming call overlay
          AnimatedOpacity(
            opacity: incomingCallOverlayVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Visibility(
              visible: incomingCallOverlayVisible,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.75),
                child: const Center(
                  child: Text(
                    '📞 Incoming Call...',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
