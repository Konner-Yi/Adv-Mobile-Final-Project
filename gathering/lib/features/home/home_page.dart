import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/map'),
            child: const Text('Map'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            child: const Text('Search'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/messages'),
            child: const Text('Messages'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/groups'),
            child: const Text('Groups'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            child: const Text('Profile'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/event'),
            child: const Text('Events'),
          ),
        ],
      ),
    );
  }
}
