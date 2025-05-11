import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/coin_purchase_page.dart';
import 'screens/recents_page.dart';
import 'screens/more_page.dart';
import 'main.dart'; // To access the routeObserver from main.dart

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => MainContainerState();
}

class MainContainerState extends State<MainContainer> with RouteAware {
  int _currentIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    fetchWalletBalance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!); // 👀 Subscribed
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // ❌ Unsubscribed
    super.dispose();
  }

  // 👇 Called when coming back from another screen (e.g., Coin Purchase)
  @override
  void didPopNext() {
    refreshWallet(); // Refresh wallet when returning
  }

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

  void refreshWallet() {
    fetchWalletBalance();
    _homeKey.currentState?.refreshWalletCoins();
  }

  void _onTabTapped(int index) async {
    if (index == 1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoinPurchasePage(
            onCoinsUpdated: () {
              Navigator.pop(context, true);
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
      HomeScreen(key: _homeKey, walletBalance: _walletBalance ?? 0.0),
      const SizedBox.shrink(), // Placeholder for Buy
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
