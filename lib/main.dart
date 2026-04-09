
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/welcome/welcome_page.dart';
import 'features/login/login_page.dart';
import 'features/registration/registration_screen.dart';
import 'features/main_nav/main_nav_page.dart';

void main() async {
  // Firebase must be initialised before anything else.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LocalLinkApp());
}

class LocalLinkApp extends StatelessWidget {
  const LocalLinkApp({super.key});

  static const Color blue   = Color(0xFF1E88E5);
  static const Color yellow = Color(0xFFFFD600);
  static const Color grey50 = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Link',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          primary: blue,
          secondary: yellow,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF212121),
        ),
        scaffoldBackgroundColor: grey50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF212121),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: blue,
            side: const BorderSide(color: blue, width: 1.5),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: blue, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF757575)),
          prefixIconColor: blue,
        ),
        progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: blue),
      ),

      home: const WelcomePage(),

      routes: {
        '/welcome':  (_) => const WelcomePage(),
        '/login':    (_) => const LoginPage(),
        '/register': (_) => const RegistrationScreen(),
        '/main':     (_) => const MainNavPage(),
      },
    );
  }
}