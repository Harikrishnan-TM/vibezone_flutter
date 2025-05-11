import 'package:flutter/material.dart';
import 'package:vibezone_app/services/auth_service.dart'; // ✅ Make sure to import AuthService
import 'screens/home_screen.dart';
import 'screens/coin_purchase_page.dart'; // ✅ Correct import
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

  // Fetch wallet balance using the new method from AuthService
  Future<void> fetchWalletBalance() async {
    final balanceData = await AuthService.getWalletBalance();
    setState(() {
      _walletBalance = balanceData['balance'];
    });
  }

  // Method to refresh wallet after coin purchase
  void refreshWallet() {
    fetchWalletBalance(); // Re-fetch wallet balance after an update (purchase)
    _homeKey.currentState?.refreshWalletCoins(); // Refresh coins on HomeScreen
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
              Navigator.pop(context, true); // Return true after coins updated
            },
          ),
        ),
      );

      if (result == true) {
        // Refresh wallet coins if purchase was successful
        refreshWallet();
      }
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(key: _homeKey, walletBalance: _walletBalance), // Pass wallet balance to HomeScreen
      const SizedBox.shrink(), // Placeholder for Buy tab
      const RecentsPage(),
      const MorePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeZone'),
        actions: [
          // You can display the wallet balance on the app bar if needed
          if (_walletBalance != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('₹${_walletBalance?.toStringAsFixed(2) ?? '0.00'}'),
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
