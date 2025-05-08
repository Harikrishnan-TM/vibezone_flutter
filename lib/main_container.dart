import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/buy_coins_screen.dart';
import 'screens/recents_page.dart';
import 'screens/more_page.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  // To allow rebuilding HomeScreen when coin purchase completes
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();

  void _onTabTapped(int index) async {
    if (index == 1) {
      // Navigate to Buy Coins page and await result
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BuyCoinsScreen()),
      );

      if (result == true) {
        // Refresh wallet if purchase happened
        _homeKey.currentState?.refreshWalletCoins();
      }
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(key: _homeKey),
      const SizedBox.shrink(), // Placeholder for Buy tab
      const RecentsPage(),
      const MorePage(),
    ];

    return Scaffold(
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
