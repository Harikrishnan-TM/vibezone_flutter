import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the URL Launcher
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class CoinPurchasePage extends StatefulWidget {
  final VoidCallback? onCoinsUpdated;

  const CoinPurchasePage({Key? key, this.onCoinsUpdated}) : super(key: key);

  @override
  State<CoinPurchasePage> createState() => _CoinPurchasePageState();
}

class _CoinPurchasePageState extends State<CoinPurchasePage> {
  bool isWebsiteSelected = true;
  int _lastAmount = 0;

  final List<Map<String, dynamic>> websitePrices = [
    {"coins": 100, "price": 100},
    {"coins": 200, "price": 200},
    {"coins": 300, "price": 300},
    {"coins": 400, "price": 400},
  ];

  final List<Map<String, dynamic>> appPrices = [
    {"coins": 100, "price": 150},
    {"coins": 200, "price": 250},
    {"coins": 300, "price": 350},
    {"coins": 400, "price": 450},
  ];

  Future<void> startWebsitePayment(int amount) async {
    _lastAmount = amount;

    final url = Uri.parse("https://vibezone-backend.fly.dev/create-order/");
    final response = await http.post(
      url,
      body: jsonEncode({"amount": amount}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Construct the Razorpay checkout URL
      final razorpayUrl = Uri.parse("https://checkout.razorpay.com/v1/checkout.js")
          .replace(queryParameters: {
        "key": data['key'] ?? 'rzp_test_...',
        "amount": data['amount'].toString(),
        "currency": "INR",
        "order_id": data['id'],
        "handler": "function (response){ window.parent.postMessage(JSON.stringify({payment_id: response.razorpay_payment_id, order_id: response.razorpay_order_id, signature: response.razorpay_signature}), '*'); }",
        "theme": "{ color: '#3399cc' }",
      });

      // Launch the Razorpay URL in the browser
      if (await canLaunch(razorpayUrl.toString())) {
        await launch(razorpayUrl.toString(), forceSafariVC: false, forceWebView: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to open payment link in browser")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create Razorpay order")),
      );
    }
  }

  Future<void> confirmPaymentOnBackend({
    required String paymentId,
    required String orderId,
    required String signature,
    required int amount,
    required String username,
  }) async {
    final url = Uri.parse("https://vibezone-backend.fly.dev/confirm-payment/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "payment_id": paymentId,
        "order_id": orderId,
        "signature": signature,
        "amount": amount,
        "username": username,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coins added successfully!")),
      );
      widget.onCoinsUpdated?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment succeeded but failed to update wallet")),
      );
    }
  }

  void handleCoinTap(Map<String, dynamic> coinData) {
    final amount = coinData['price'];
    if (isWebsiteSelected) {
      startWebsitePayment(amount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("In-app payment not available yet")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prices = isWebsiteSelected ? websitePrices : appPrices;

    return Scaffold(
      appBar: AppBar(title: const Text("Buy Coins")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [isWebsiteSelected, !isWebsiteSelected],
              onPressed: (index) {
                setState(() => isWebsiteSelected = index == 0);
              },
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("On Website")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("On App")),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: prices.map((data) {
                  return GestureDetector(
                    onTap: () => handleCoinTap(data),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${data["coins"]} Coins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text('₹${data["price"]}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
