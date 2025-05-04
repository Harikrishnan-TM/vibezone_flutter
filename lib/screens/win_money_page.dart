import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/auth_service.dart';
import 'withdraw_status_screen.dart';

class WinMoneyPage extends StatefulWidget {
  final int initialEarningCoins;

  const WinMoneyPage({
    Key? key,
    required this.initialEarningCoins,
  }) : super(key: key);

  @override
  State<WinMoneyPage> createState() => _WinMoneyPageState();
}

class _WinMoneyPageState extends State<WinMoneyPage> {
  int earningCoins = 0;
  bool isKycCompleted = false;
  bool isLoading = true;
  String? authToken;

  final String baseUrl = 'https://vibezone-backend.fly.dev';

  @override
  void initState() {
    super.initState();
    earningCoins = widget.initialEarningCoins;
    _loadTokenAndCheckKyc();
  }

  Future<void> _loadTokenAndCheckKyc() async {
    authToken = await AuthService.getToken();
    if (authToken == null) {
      _showSnackBar('User not logged in. Please login again.');
      setState(() => isLoading = false);
      return;
    }
    await _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/get-kyc-status/'),
        headers: {'Authorization': 'Token $authToken'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          isKycCompleted =
              (data['kyc_status'] ?? '').toString().toLowerCase() == 'approved';
          isLoading = false;
        });
      } else {
        _showSnackBar('Failed to fetch KYC status.');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Something went wrong while fetching KYC status.');
      setState(() => isLoading = false);
    }
  }

  Future<void> _requestWithdrawal() async {
    if (authToken == null) {
      _showSnackBar('User not authenticated.');
      return;
    }

    if (earningCoins == 0) {
      _showSnackBar('You have no earnings to withdraw.');
      return;
    }

    final url = Uri.parse('$baseUrl/request-withdrawal/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({'coins': earningCoins}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? 'Withdrawal requested.');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WithdrawStatusScreen(
              amount: earningCoins.toDouble(),
              status: 'Pending',
            ),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(error['error'] ?? 'Withdrawal failed.');
      }
    } catch (e) {
      _showSnackBar('Something went wrong. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double rupeeAmount = earningCoins.toDouble();

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
                    '($earningCoins withdrawable coins)',
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
                          onPressed: () => Navigator.pushNamed(context, '/kyc'),
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
                        _requestWithdrawal();
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
