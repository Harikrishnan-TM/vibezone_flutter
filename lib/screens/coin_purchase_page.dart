import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher_string.dart';
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
  StreamSubscription? _sub;

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

  @override
  void initState() {
    super.initState();
    _listenToDeepLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenToDeepLinks() {
    _sub = uriLinkStream.listen((Uri? uri) async {
      debugPrint('[uni_links] Received deep link: $uri');
      if (uri != null &&
          uri.scheme == 'myapp' &&
          uri.host == 'payment-success') {
        final paymentId = uri.queryParameters['payment_id'];
        final orderId = uri.queryParameters['order_id'];
        final signature = uri.queryParameters['signature'];

        debugPrint('[uni_links] payment_id=$paymentId, order_id=$orderId, signature=$signature');

        final username = await AuthService.getUsername();
        if (paymentId != null && orderId != null && signature != null && username != null) {
          await confirmPaymentOnBackend(
            paymentId: paymentId,
            orderId: orderId,
            signature: signature,
            amount: _lastAmount,
            username: username,
          );
        } else {
          debugPrint('[uni_links] Missing one or more required parameters.');
        }
      }
    }, onError: (err) {
      debugPrint('[uni_links] Deep link error: $err');
    });
  }

  Future<void> startWebsitePayment(int amount) async {
    _lastAmount = amount;
    debugPrint('[startWebsitePayment] Starting payment for amount: $amount');

    final url = Uri.parse("https://vibezone-backend.fly.dev/create-order/");
    try {
      final response = await http.post(
        url,
        body: jsonEncode({"amount": amount}),
        headers: {"Content-Type": "application/json"},
      );

      debugPrint('[startWebsitePayment] Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final username = await AuthService.getUsername();

        if (username == null) {
          debugPrint('[startWebsitePayment] Username is null');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not logged in")),
          );
          return;
        }

        final String key = data['key'] ?? '';
        if (key.isEmpty) {
          debugPrint('[startWebsitePayment] Razorpay key missing in response');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment error: missing Razorpay key")),
          );
          return;
        }

        final Uri paymentUrl = Uri.parse(
          'https://techno-official.github.io/vibezone-payment-page/checkout.html'
          '?order_id=${data['id']}&amount=${data['amount']}&key=$key&username=$username',
        );

        debugPrint('[startWebsitePayment] Final payment URL: $paymentUrl');

        try {
          final launched = await launchUrlString(
            paymentUrl.toString(),
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            throw 'launchUrlString returned false';
          }
        } catch (e) {
          debugPrint('[startWebsitePayment] Failed to launch URL: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch payment URL")),
          );
        }
      } else {
        debugPrint('[startWebsitePayment] Failed to create Razorpay order');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create Razorpay order")),
        );
      }
    } catch (e) {
      debugPrint('[startWebsitePayment] Exception during payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch payment URL")),
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
    debugPrint('[confirmPaymentOnBackend] Confirming payment on backend...');
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

    debugPrint('[confirmPaymentOnBackend] Response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coins added successfully!")),
      );
      widget.onCoinsUpdated?.call();
      if (mounted) {
        Navigator.pop(context, true); // ✅ Return `true` to notify parent
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment succeeded but failed to update wallet")),
      );
    }
  }

  void handleCoinTap(Map<String, dynamic> coinData) {
    final amount = coinData['price'];
    debugPrint('[handleCoinTap] User tapped coin box for ₹$amount');
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
