import 'package:flutter/material.dart';
import 'services/auth_service.dart'; // ✅ Correct relative import
import 'screens/home_screen.dart';
import 'screens/coin_purchase_page.dart';
import 'screens/recents_page.dart';
import 'screens/more_page.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => MainContainerState();
}

class MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  // To allow rebuilding HomeScreen when coin purchase completes
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();

  // For storing wallet balance
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    fetchWalletBalance(); // Fetch wallet balance when the app starts
  }

  // Fetch wallet balance using AuthService
  Future<void> fetchWalletBalance() async {
    try {
      final balanceData = await AuthService.fetchWalletBalance();
      setState(() {
        _walletBalance = balanceData?['balance']?.toDouble() ?? 0.0;
      });
    } catch (e) {
      debugPrint("Error fetching wallet balance: $e");
    }
  }

  // Method to refresh wallet after coin purchase
  void refreshWallet() {
    fetchWalletBalance(); // Re-fetch wallet balance after an update (purchase)
    _homeKey.currentState?.refreshWalletCoins(); // Refresh HomeScreen if needed
  }

  // Tab selection handling
  void _onTabTapped(int index) async {
    if (index == 1) {
      // Navigate to CoinPurchasePage
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoinPurchasePage(
            onCoinsUpdated: () {
              Navigator.pop(context, true); // Return true if coins were updated
            },
          ),
        ),
      );

      if (result == true) {
        refreshWallet();
      }
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(key: _homeKey, walletBalance: _walletBalance ?? 0.0), // ✅ Pass wallet balance
      const SizedBox.shrink(), // Placeholder for Buy tab
      const RecentsPage(),
      const MorePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeZone'),
        actions: [
          if (_walletBalance != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '₹${_walletBalance!.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Buy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Recents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
