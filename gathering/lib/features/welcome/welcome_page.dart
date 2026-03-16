// // import 'package:flutter/material.dart';
// // import '../login/login_page.dart';
// // import '../registration/registration_screen.dart';
// // import '../main_nav/main_nav_page.dart';
// // import '../../core/services/auth_database.dart';
// //
// // class WelcomePage extends StatefulWidget {
// //   const WelcomePage({super.key});
// //
// //   @override
// //   State<WelcomePage> createState() => _WelcomePageState();
// // }
// //
// // class _WelcomePageState extends State<WelcomePage> {
// //   final AuthDatabase _authDatabase = AuthDatabase();
// //   bool _isChecking = true;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkIfLoggedIn();
// //   }
// //
// //   Future<void> _checkIfLoggedIn() async {
// //     final user = await _authDatabase.getCurrentUser();
// //
// //     if (user != null && mounted) {
// //       // User is already logged in, go to main nav page
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder: (context) => const MainNavPage(),
// //         ),
// //       );
// //     } else {
// //       setState(() {
// //         _isChecking = false;
// //       });
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (_isChecking) {
// //       return const Scaffold(
// //         body: Center(
// //           child: CircularProgressIndicator(),
// //         ),
// //       );
// //     }
// //
// //     return Scaffold(
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topRight,
// //             end: Alignment.bottomLeft,
// //             colors: [Colors.blue, Colors.purple],
// //           ),
// //         ),
// //         child: Center(
// //           child: Container(
// //             width: 400,
// //             padding: const EdgeInsets.all(32),
// //             decoration: BoxDecoration(
// //               color: Colors.white,
// //               borderRadius: BorderRadius.circular(20),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: Colors.black.withOpacity(0.2),
// //                   blurRadius: 30,
// //                   spreadRadius: 5,
// //                 ),
// //               ],
// //             ),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 const Text(
// //                   'Local Link',
// //                   style: TextStyle(
// //                     fontSize: 42,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 10),
// //                 const Text(
// //                   'Find places, people, and events near you.',
// //                   textAlign: TextAlign.center,
// //                   style: TextStyle(
// //                     color: Colors.grey,
// //                     fontSize: 16,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 40),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: ElevatedButton(
// //                     onPressed: () {
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (context) => const LoginPage(),
// //                         ),
// //                       );
// //                     },
// //                     style: ElevatedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 16),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(10),
// //                       ),
// //                     ),
// //                     child: const Text(
// //                       'Login',
// //                       style: TextStyle(fontSize: 18),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 16),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton(
// //                     onPressed: () {
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (context) => const RegistrationScreen(),
// //                         ),
// //                       );
// //                     },
// //                     style: OutlinedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 16),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(10),
// //                       ),
// //                     ),
// //                     child: const Text(
// //                       'Register',
// //                       style: TextStyle(fontSize: 18),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 30),
// //                 const Text(
// //                   'or try demo',
// //                   style: TextStyle(color: Colors.grey),
// //                 ),
// //                 const SizedBox(height: 10),
// //                 TextButton(
// //                   onPressed: () {
// //                     Navigator.pushReplacement(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (context) => const MainNavPage(),
// //                       ),
// //                     );
// //                   },
// //                   child: const Text('Continue as Guest'),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import '../login/login_page.dart';
// import '../registration/registration_screen.dart';
// import '../main_nav/main_nav_page.dart';
// import '../../core/services/auth_database.dart';
//
// class WelcomePage extends StatefulWidget {
//   const WelcomePage({super.key});
//
//   @override
//   State<WelcomePage> createState() => _WelcomePageState();
// }
//
// class _WelcomePageState extends State<WelcomePage> {
//   final AuthDatabase _authDatabase = AuthDatabase();
//   bool _isChecking = true;
//
//   // ── Theme colours ────────────────────────────────────────────────────────
//   static const Color blue    = Color(0xFF1E88E5);
//   static const Color yellow  = Color(0xFFFFD600);
//   static const Color white   = Color(0xFFFFFFFF);
//   static const Color grey50  = Color(0xFFFAFAFA);
//   static const Color grey200 = Color(0xFFEEEEEE);
//   static const Color grey600 = Color(0xFF757575);
//   static const Color grey900 = Color(0xFF212121);
//
//   @override
//   void initState() {
//     super.initState();
//     _checkIfLoggedIn();
//   }
//
//   Future<void> _checkIfLoggedIn() async {
//     final user = await _authDatabase.getCurrentUser();
//     if (user != null && mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const MainNavPage()),
//       );
//     } else {
//       setState(() => _isChecking = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isChecking) {
//       return const Scaffold(
//         backgroundColor: white,
//         body: Center(
//           child: CircularProgressIndicator(color: blue),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: grey50,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // ── Logo ──────────────────────────────────────────────────
//                 Container(
//                   width: 72,
//                   height: 72,
//                   decoration: const BoxDecoration(
//                     color: blue,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Center(
//                     child: Icon(Icons.location_on, color: yellow, size: 38),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//
//                 const Text(
//                   'Local Link',
//                   style: TextStyle(
//                     fontSize: 36,
//                     fontWeight: FontWeight.bold,
//                     color: grey900,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Find places, people, and events near you.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: grey600,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//
//                 // ── Login button ─────────────────────────────────────────
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const LoginPage()),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: blue,
//                       foregroundColor: white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: const Text(
//                       'Login',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//
//                 // ── Register button ──────────────────────────────────────
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const RegistrationScreen()),
//                       );
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: blue,
//                       side: const BorderSide(color: blue, width: 1.5),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Register',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//
//                 // ── Guest ────────────────────────────────────────────────
//                 const Text('or', style: TextStyle(color: grey600)),
//                 const SizedBox(height: 8),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (_) => const MainNavPage()),
//                     );
//                   },
//                   child: const Text(
//                     'Continue as Guest',
//                     style: TextStyle(
//                       color: grey600,
//                       fontSize: 14,
//                       decoration: TextDecoration.underline,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login/login_page.dart';
import '../registration/registration_screen.dart';
import '../main_nav/main_nav_page.dart';

/// Listens to Firebase's auth state stream.
/// If a user is already signed in, goes straight to MainNavPage.
/// Otherwise shows the welcome / splash screen.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Still waiting for Firebase to respond
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: blue),
            ),
          );
        }

        // Already logged in → skip straight to the app
        if (snapshot.hasData) {
          return const MainNavPage();
        }

        // Not logged in → show welcome screen
        return Scaffold(
          backgroundColor: grey50,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on,
                            color: yellow, size: 38),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Local Link',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: grey900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find places, people, and events near you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: grey600, fontSize: 15),
                    ),
                    const SizedBox(height: 40),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginPage()),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const RegistrationScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Guest
                    const Text('or', style: TextStyle(color: grey600)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MainNavPage()),
                      ),
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: grey600,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}