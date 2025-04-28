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
  bool _isLoading = false;  // Track loading state for better user experience

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
      _isLoading = true;  // Set loading state to true when starting the purchase
      _message = null;  // Clear previous messages
    });

    try {
      final response = await ApiService.buyCoins(coins);  // Interact with the backend
      if (response != null && response['message'] != null) {
        setState(() {
          _message = response['message'];  // Success or failure message from backend
        });
      } else {
        setState(() {
          _message = 'Failed to purchase coins. Try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'An error occurred while purchasing coins: $e';  // Handle any network or server error
      });
    } finally {
      setState(() {
        _isLoading = false;  // Set loading state to false once the operation is complete
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
              onPressed: _isLoading ? null : _buyCoins,  // Disable button while loading
              child: _isLoading
                  ? const CircularProgressIndicator()  // Show loading indicator when buying coins
                  : const Text('Buy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,  // Updated to use backgroundColor
                foregroundColor: Colors.white,       // Optional: set text color
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            if (_message != null) ...[
              Text(
                _message!,
                style: TextStyle(
                  fontSize: 16,
                  color: _message == 'Coins purchased successfully!' ? Colors.green : Colors.red,
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.pop(context);  // Navigate back to the home screen
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
