import 'package:flutter/material.dart';
import 'package:vibezone_flutter/services/api_service.dart';  // Import ApiService for backend interaction

class BuyCoinsScreen extends StatefulWidget {
  const BuyCoinsScreen({super.key});

  @override
  _BuyCoinsScreenState createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends State<BuyCoinsScreen> {
  final _coinsController = TextEditingController();
  String? _message;
  bool _isLoading = false;

  @override
  void dispose() {
    _coinsController.dispose();
    super.dispose();
  }

  // Method to handle coin purchasing logic
  Future<void> _buyCoins() async {
    final coins = int.tryParse(_coinsController.text);
    if (coins == null || coins < 1) {
      setState(() {
        _message = 'Please enter a valid amount of coins to buy.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await ApiService.buyCoins(coins);

      if (response != null && response['message'] != null) {
        final success = response['message'].toLowerCase().contains('success');
        setState(() {
          _message = response['message'];
        });

        if (success) {
          // Wait briefly, then return to home to trigger wallet refresh
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) Navigator.pop(context, true); // return true so wallet refreshes
          });
        }

      } else {
        setState(() {
          _message = 'Failed to purchase coins. Try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'An error occurred while purchasing coins: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Coins'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            const Text(
              'Enter coins to buy:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _coinsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Coins',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _buyCoins,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Buy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            if (_message != null) ...[
              Text(
                _message!,
                style: TextStyle(
                  fontSize: 16,
                  color: _message == 'Coins purchased successfully!' || _message!.toLowerCase().contains('success')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
