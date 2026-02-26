import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home/home_page.dart';
import '../map/map_page.dart';
import '../search/search_page.dart';
import '../messages/messages_page.dart';
import '../profile/profile_page.dart';

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  void _goToMapTab() {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onOpenMap: _goToMapTab),
      const MapPage(),
      const SearchPage(),
      const MessagesPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF5C6BC0),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // ✅ Bright, rounded, elevated gradient nav
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00C6FF), // bright cyan
                  Color(0xFF7F00FF), // bright purple
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,

                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white.withOpacity(0.75),

                selectedFontSize: 12,
                unselectedFontSize: 12,
                showUnselectedLabels: true,

                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
                  BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                  BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}