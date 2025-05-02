import 'package:flutter/material.dart';
import 'withdraw_status_screen.dart'; // Ensure this import is correct

class WinMoneyPage extends StatelessWidget {
  final int walletCoins;
  final bool isKycCompleted;

  const WinMoneyPage({
    Key? key,
    required this.walletCoins,
    required this.isKycCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double rupeeAmount = walletCoins.toDouble(); // 1 coin = ₹1

    return Scaffold(
      appBar: AppBar(
        title: const Text('Win Money 💰'),
        centerTitle: true,
      ),
      body: Padding(
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
            ),
            const SizedBox(height: 30),

            // KYC STATUS
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

            // Withdraw Button
            ElevatedButton(
              onPressed: () {
                if (isKycCompleted) {
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
