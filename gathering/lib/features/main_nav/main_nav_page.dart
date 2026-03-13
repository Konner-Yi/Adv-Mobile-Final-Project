// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// //
// // import '../home/home_page.dart';
// // import '../map/map_page.dart';
// // import '../search/search_page.dart';
// // import '../messages/messages_page.dart';
// // import '../profile/profile_page.dart';
// //
// // class MainNavPage extends StatefulWidget {
// //   const MainNavPage({super.key});
// //
// //   @override
// //   State<MainNavPage> createState() => _MainNavPageState();
// // }
// //
// // class _MainNavPageState extends State<MainNavPage> {
// //   int _selectedIndex = 0;
// //
// //   void _onItemTapped(int index) {
// //     HapticFeedback.selectionClick();
// //     setState(() => _selectedIndex = index);
// //   }
// //
// //   void _goToMapTab() {
// //     HapticFeedback.selectionClick();
// //     setState(() => _selectedIndex = 1);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final pages = [
// //       HomePage(onOpenMap: _goToMapTab),
// //       const MapPage(),
// //       const SearchPage(),
// //       const MessagesPage(),
// //       const ProfilePage(),
// //     ];
// //
// //     return Scaffold(
// //       extendBody: true,
// //       backgroundColor: const Color(0xFF5C6BC0),
// //       body: IndexedStack(
// //         index: _selectedIndex,
// //         children: pages,
// //       ),
// //
// //       bottomNavigationBar: SafeArea(
// //         top: false,
// //         child: Padding(
// //           padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
// //           child: Container(
// //             decoration: BoxDecoration(
// //               borderRadius: BorderRadius.circular(24),
// //               gradient: const LinearGradient(
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //                 colors: [
// //                   Color(0xFF00C6FF),
// //                   Color(0xFF7F00FF),
// //                 ],
// //               ),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: Colors.black.withOpacity(0.18),
// //                   blurRadius: 18,
// //                   offset: const Offset(0, 10),
// //                 ),
// //               ],
// //             ),
// //             child: ClipRRect(
// //               borderRadius: BorderRadius.circular(24),
// //               child: BottomNavigationBar(
// //                 currentIndex: _selectedIndex,
// //                 onTap: _onItemTapped,
// //                 type: BottomNavigationBarType.fixed,
// //                 backgroundColor: Colors.transparent,
// //                 elevation: 0,
// //
// //                 selectedItemColor: Colors.white,
// //                 unselectedItemColor: Colors.white.withOpacity(0.75),
// //
// //                 selectedFontSize: 12,
// //                 unselectedFontSize: 12,
// //                 showUnselectedLabels: true,
// //
// //                 items: const [
// //                   BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
// //                   BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
// //                   BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
// //                   BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
// //                   BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import '../home/home_page.dart';
// import '../map/map_page.dart';
// import '../search/search_page.dart';
// import '../messages/messages_page.dart';
// import '../profile/profile_page.dart';
//
// class MainNavPage extends StatefulWidget {
//   const MainNavPage({super.key});
//
//   @override
//   State<MainNavPage> createState() => _MainNavPageState();
// }
//
// class _MainNavPageState extends State<MainNavPage> {
//   // ── Start on the Map tab (index 1) ──────────────────────────────────────
//   int _selectedIndex = 1;
//
//   // ── Theme colours ────────────────────────────────────────────────────────
//   static const Color blue   = Color(0xFF1E88E5);
//   static const Color yellow = Color(0xFFFFD600);
//   static const Color white  = Color(0xFFFFFFFF);
//   static const Color grey50 = Color(0xFFFAFAFA);
//   static const Color grey200 = Color(0xFFEEEEEE);
//   static const Color grey500 = Color(0xFF9E9E9E);
//
//   void _onItemTapped(int index) {
//     HapticFeedback.selectionClick();
//     setState(() => _selectedIndex = index);
//   }
//
//   void _goToMapTab() {
//     HapticFeedback.selectionClick();
//     setState(() => _selectedIndex = 1);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final pages = [
//       HomePage(onOpenMap: _goToMapTab),
//       const MapPage(),
//       const SearchPage(),
//       const MessagesPage(),
//       const ProfilePage(),
//     ];
//
//     return Scaffold(
//       extendBody: true,
//       backgroundColor: grey50,
//       body: IndexedStack(
//         index: _selectedIndex,
//         children: pages,
//       ),
//
//       bottomNavigationBar: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(24),
//               color: white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.10),
//                   blurRadius: 20,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: BottomNavigationBar(
//                 currentIndex: _selectedIndex,
//                 onTap: _onItemTapped,
//                 type: BottomNavigationBarType.fixed,
//                 backgroundColor: Colors.transparent,
//                 elevation: 0,
//
//                 selectedItemColor: blue,
//                 unselectedItemColor: grey500,
//
//                 selectedFontSize: 11,
//                 unselectedFontSize: 11,
//                 showUnselectedLabels: true,
//
//                 items: [
//                   const BottomNavigationBarItem(
//                     icon: Icon(Icons.home_outlined),
//                     activeIcon: Icon(Icons.home),
//                     label: 'Home',
//                   ),
//                   BottomNavigationBarItem(
//                     icon: const Icon(Icons.map_outlined),
//                     activeIcon: Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         const Icon(Icons.map, color: blue),
//                         Positioned(
//                           top: -4,
//                           right: -4,
//                           child: Container(
//                             width: 8,
//                             height: 8,
//                             decoration: const BoxDecoration(
//                               color: yellow,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     label: 'Map',
//                   ),
//                   const BottomNavigationBarItem(
//                     icon: Icon(Icons.search_outlined),
//                     activeIcon: Icon(Icons.search),
//                     label: 'Search',
//                   ),
//                   const BottomNavigationBarItem(
//                     icon: Icon(Icons.chat_bubble_outline),
//                     activeIcon: Icon(Icons.chat_bubble),
//                     label: 'Messages',
//                   ),
//                   const BottomNavigationBarItem(
//                     icon: Icon(Icons.person_outline),
//                     activeIcon: Icon(Icons.person),
//                     label: 'Profile',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home/home_page.dart';
import '../map/map_page.dart';
import '../search/search_page.dart';
import '../messages/messages_page.dart';
import '../profile/profile_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab indices (stable — never change these, everything else references them)
// ─────────────────────────────────────────────────────────────────────────────
const int _kHome     = 0;
const int _kMap      = 1;
const int _kSearch   = 2;
const int _kMessages = 3;
const int _kProfile  = 4;

class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int _selectedIndex = _kMap; // open on Map

  void _go(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  void _goToMap() => _go(_kMap);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onOpenMap: _goToMap),
      const MapPage(),
      const SearchPage(),
      const MessagesPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFAFAFA),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _DynamicNavBar(
        selectedIndex: _selectedIndex,
        onTap: _go,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic nav bar
// ─────────────────────────────────────────────────────────────────────────────
class _DynamicNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _DynamicNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey900 = Color(0xFF212121);

  bool get _onMapPage => selectedIndex == _kMap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 64,
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _onMapPage
                  ? _mapLayout(key: const ValueKey('map'))
                  : _defaultLayout(key: const ValueKey('default')),
            ),
          ),
        ),
      ),
    );
  }

  // ── Map page layout: [Home]  [Map]  [── Search ──] ───────────────────────
  Widget _mapLayout({Key? key}) {
    return Row(
      key: key,
      children: [
        _IconBtn(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          active: selectedIndex == _kHome,
          onTap: () => onTap(_kHome),
        ),
        _IconBtn(
          icon: Icons.map_outlined,
          activeIcon: Icons.map,
          label: 'Map',
          active: selectedIndex == _kMap,
          onTap: () => onTap(_kMap),
        ),
        const SizedBox(width: 6),
        // Wide Search pill — fills remaining space
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(_kSearch);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: selectedIndex == _kSearch ? grey900 : blue,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedIndex == _kSearch
                        ? Icons.search
                        : Icons.search_outlined,
                    color: selectedIndex == _kSearch ? yellow : white,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Search',
                    style: TextStyle(
                      color: selectedIndex == _kSearch ? yellow : white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Default layout: [Profile] [Messages] [Home] [Map] ────────────────────
  Widget _defaultLayout({Key? key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _IconBtn(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          active: selectedIndex == _kProfile,
          onTap: () => onTap(_kProfile),
        ),
        _IconBtn(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          label: 'Messages',
          active: selectedIndex == _kMessages,
          onTap: () => onTap(_kMessages),
        ),
        _IconBtn(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          active: selectedIndex == _kHome,
          onTap: () => onTap(_kHome),
        ),
        _IconBtn(
          icon: Icons.map_outlined,
          activeIcon: Icons.map,
          label: 'Map',
          active: selectedIndex == _kMap,
          accent: true,
          onTap: () => onTap(_kMap),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable icon button for the nav bar
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool accent;
  final VoidCallback onTap;

  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color grey500 = Color(0xFF9E9E9E);

  const _IconBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    active ? activeIcon : icon,
                    key: ValueKey(active),
                    color: active ? blue : grey500,
                    size: 24,
                  ),
                ),
                // Yellow dot on Map icon when active
                if (accent && active)
                  Positioned(
                    top: -3,
                    right: -4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: active ? blue : grey500,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}