// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../core/services/auth_database.dart';
//
// class MessagesPage extends StatelessWidget {
//   const MessagesPage({super.key});
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
//           'Messages',
//           style: TextStyle(
//             color: cyan,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: cyan),
//             onPressed: () async {
//               HapticFeedback.selectionClick();
//               await AuthDatabase().logout();
//               if (context.mounted) {
//                 Navigator.pushReplacementNamed(context, '/login');
//               }
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
//             'Messages will go here',
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
import 'package:flutter/services.dart';
import '../../core/services/auth_database.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

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
          'Messages',
          style: TextStyle(
            color: grey900,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: blue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: grey600),
            onPressed: () async {
              HapticFeedback.selectionClick();
              await AuthDatabase().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: grey200),
        ),
      ),

      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: grey200),
            SizedBox(height: 16),
            Text(
              'Messages will go here',
              style: TextStyle(
                color: grey600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}