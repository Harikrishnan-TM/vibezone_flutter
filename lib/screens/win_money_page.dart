import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/auth_service.dart';
import 'withdraw_status_screen.dart';

class WinMoneyPage extends StatefulWidget {
  const WinMoneyPage({Key? key}) : super(key: key);

  @override
  State<WinMoneyPage> createState() => _WinMoneyPageState();
}

class _WinMoneyPageState extends State<WinMoneyPage> {
  int walletCoins = 0;
  bool isKycCompleted = false;
  bool isLoading = true;
  String? authToken;

  final String baseUrl = 'https://vibezone-backend.fly.dev';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    authToken = await AuthService.getToken();
    if (authToken == null) {
      showError('User not logged in. Please login again.');
      setState(() => isLoading = false);
      return;
    }
    await fetchWalletAndKycStatus();
  }

  Future<void> fetchWalletAndKycStatus() async {
    try {
      final walletRes = await http.get(
        Uri.parse('$baseUrl/get-earnings-wallet/'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      final kycRes = await http.get(
        Uri.parse('$baseUrl/get-kyc-status/'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (walletRes.statusCode == 200 && kycRes.statusCode == 200) {
        final walletData = jsonDecode(walletRes.body);
        final kycData = jsonDecode(kycRes.body);

        setState(() {
          walletCoins = walletData['data']['earnings_coins'] ?? 0;
          isKycCompleted = (kycData['kyc_status'] ?? '').toLowerCase() == 'approved';
          isLoading = false;
        });
      } else {
        showError('Failed to fetch wallet or KYC data.');
        setState(() => isLoading = false);
      }
    } catch (e) {
      showError('Something went wrong while fetching data.');
      setState(() => isLoading = false);
    }
  }

  Future<void> _requestWithdrawal(BuildContext context) async {
    if (authToken == null) {
      showError('User not authenticated.');
      return;
    }

    final url = Uri.parse('$baseUrl/request-withdrawal/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'coins': walletCoins}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Withdrawal requested.')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WithdrawStatusScreen(
              amount: walletCoins.toDouble(),
              status: 'Pending',
            ),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        showError(error['error'] ?? 'Withdrawal failed.');
      }
    } catch (e) {
      showError('Something went wrong. Please try again.');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double rupeeAmount = walletCoins.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Win Money 💰'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'You have ₹${rupeeAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '($walletCoins coins in your wallet)',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'KYC Status: ${isKycCompleted ? 'Completed' : 'Pending'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      if (!isKycCompleted)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/kyc');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          child: const Text('Verify KYC'),
                        ),
                    ],
                  ),

                  const Spacer(),

                  ElevatedButton(
                    onPressed: () {
                      if (isKycCompleted) {
                        _requestWithdrawal(context);
                      } else {
                        Navigator.pushNamed(context, '/kyc');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Withdraw'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
