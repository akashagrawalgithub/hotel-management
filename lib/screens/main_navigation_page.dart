import 'package:flutter/material.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'my_bookings_page.dart';
import 'find_page.dart';
import 'favorites_page.dart';
import '../widgets/custom_bottom_nav.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const HomePage(),
    FindPage(onBackPressed: () {
      setState(() {
        _currentIndex = 0;
      });
    }),
    const FavoritesPage(),
    MyBookingsPage(onBackPressed: () {
      setState(() {
        _currentIndex = 0;
      });
    }),
    SettingsPage(onBackPressed: () {
      setState(() {
        _currentIndex = 0;
      });
    }),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: _pages[_currentIndex],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}

