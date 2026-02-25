import 'package:flutter/material.dart';

import 'features/welcome/welcome_page.dart';
import 'features/login/login_page.dart';
import 'features/registration/registration_screen.dart';
import 'features/main_nav/main_nav_page.dart';

void main() {
  runApp(const LocalLinkApp());
}

class LocalLinkApp extends StatelessWidget {
  const LocalLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Link',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      home: const WelcomePage(),

      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegistrationScreen(),
        '/main': (_) => const MainNavPage(),
      },
    );
  }
}