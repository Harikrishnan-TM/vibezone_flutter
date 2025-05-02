import 'package:flutter/material.dart';

class WithdrawStatusScreen extends StatelessWidget {
  final double amount; // Pass this from previous screen if needed
  final String status; // Example: 'Pending' or 'Transferred'

  const WithdrawStatusScreen({
    Key? key,
    this.amount = 0.0,
    this.status = 'Pending',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Status'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              '₹${amount.toStringAsFixed(2)} will be transferred to your bank account.',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Status: ', style: TextStyle(fontSize: 18)),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    color: status == 'Transferred' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to WinMoneyPage
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
