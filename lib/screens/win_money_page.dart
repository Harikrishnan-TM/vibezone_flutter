import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Ensure this contains fetchProfile()

class WinMoneyPage extends StatefulWidget {
  final int walletCoins;

  const WinMoneyPage({Key? key, required this.walletCoins}) : super(key: key);

  @override
  State<WinMoneyPage> createState() => _WinMoneyPageState();
}

class _WinMoneyPageState extends State<WinMoneyPage> {
  String kycStatus = 'Pending'; // Default
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    try {
      final profile = await ApiService.fetchProfile();
      if (mounted && profile != null && profile['success'] == true && profile['data'] != null) {
        final status = (profile['data']['kyc_status'] ?? 'pending').toString().toLowerCase();
        setState(() {
          kycStatus = status == 'completed' ? 'Completed' : 'Pending';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load KYC status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double rupeeAmount = widget.walletCoins.toDouble(); // 1 coin = ₹1

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
                    '(${widget.walletCoins} coins in your wallet)',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // KYC STATUS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'KYC Status: $kycStatus',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      if (kycStatus == 'Pending')
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

                  // Withdraw Button
                  ElevatedButton(
                    onPressed: () {
                      if (kycStatus == 'Completed') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WithdrawStatusScreen(
                              amount: rupeeAmount,
                              status: 'Pending',
                            ),
                          ),
                        );
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
