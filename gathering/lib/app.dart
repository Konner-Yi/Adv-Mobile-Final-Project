import 'package:flutter/material.dart';

import 'features/login/login_page.dart';
import 'features/login/new_account_page.dart';
import 'features/home/home_page.dart';
import 'features/map/map_page.dart';
import 'features/profile/profile_page.dart';
import 'features/search/search_page.dart';
import 'features/messages/messages_page.dart';
import 'features/groups/groups_page.dart';
import 'features/event/event_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gathering',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/newAccount': (context) => const NewAccountPage(),
        '/home': (context) => const HomePage(),
        '/map': (context) => const MapPage(),
        '/profile': (context) => const ProfilePage(),
        '/search': (context) => const SearchPage(),
        '/messages': (context) => const MessagesPage(),
        '/groups': (context) => const GroupsPage(),
        '/event': (context) => const EventPage(),
      },
    );
  }
}
