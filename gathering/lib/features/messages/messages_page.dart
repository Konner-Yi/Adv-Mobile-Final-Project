import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_database.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  static const Color cyan = Color(0xFF00E5FF);
  static const Color indigo = Color(0xFF3949AB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: indigo,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: cyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: cyan),
            onPressed: () async {
              HapticFeedback.selectionClick();
              await AuthDatabase().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5C6BC0),
              Color(0xFF5C6BC0),
            ],
          ),
        ),
        child: const Center(
          child: Text(
            'Messages will go here',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}