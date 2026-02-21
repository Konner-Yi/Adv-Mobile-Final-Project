import 'package:flutter/material.dart';
import 'features/welcome/welcome_page.dart';
import 'features/login/login_page.dart';
import 'features/registration/registration_screen.dart';
import 'features/home/home_page.dart';
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
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}