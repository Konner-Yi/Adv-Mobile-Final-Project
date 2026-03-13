// import 'package:flutter/material.dart';
//
// class SearchPage extends StatelessWidget {
//   const SearchPage({super.key});
//
//   static const Color cyan = Color(0xFF00E5FF);
//   static const Color indigo = Color(0xFF3949AB);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//
//       appBar: AppBar(
//         backgroundColor: indigo,
//         elevation: 0,
//         title: const Text(
//           'Search',
//           style: TextStyle(
//             color: cyan,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: cyan),
//             onPressed: () {
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//           ),
//         ],
//       ),
//
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF5C6BC0),
//               Color(0xFF5C6BC0),
//             ],
//           ),
//         ),
//         child: const Center(
//           child: Text(
//             'Search functionality will go here',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey50,

      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Search',
          style: TextStyle(
            color: grey900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: grey200),
        ),
      ),

      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: white,
                border: Border.all(color: grey200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search people, places, events…',
                  hintStyle: const TextStyle(color: grey600, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: blue),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: yellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune, color: grey900, size: 18),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 56, color: grey200),
                  SizedBox(height: 16),
                  Text(
                    'Search functionality will go here',
                    style: TextStyle(
                      color: grey600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}