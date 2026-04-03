// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../core/services/auth_database.dart';
// import '../main_nav/main_nav_page.dart';
// import '../welcome/welcome_page.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final AuthDatabase _authDatabase = AuthDatabase();
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   String _errorMessage = '';
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _login() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = '';
//       });
//
//       final email = _emailController.text.trim();
//       final password = _passwordController.text.trim();
//
//       final user = await _authDatabase.authenticate(email, password);
//
//       setState(() {
//         _isLoading = false;
//       });
//
//       if (user != null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const MainNavPage(),
//           ),
//         );
//       } else {
//         setState(() {
//           _errorMessage = 'Invalid email or password';
//         });
//         HapticFeedback.vibrate();
//       }
//     }
//   }
//
//   void _onLoginPressed() {
//     HapticFeedback.mediumImpact();
//     _login();
//   }
//
//   void _onGuestPressed() {
//     HapticFeedback.mediumImpact();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const MainNavPage(),
//       ),
//     );
//   }
//
//   Future<void> _testCredentials() async {
//     HapticFeedback.selectionClick();
//     _emailController.text = 'test@example.com';
//     _passwordController.text = 'password123';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             HapticFeedback.selectionClick();
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const WelcomePage(),
//               ),
//             );
//           },
//         ),
//         title: const Text('Login'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.bug_report),
//             onPressed: _testCredentials,
//             tooltip: 'Fill test credentials',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 40),
//                 const Text(
//                   'Welcome Back',
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   'Sign in to continue',
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 if (_errorMessage.isNotEmpty)
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     margin: const EdgeInsets.only(bottom: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.red[50],
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.red[100]!),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.error_outline, color: Colors.red, size: 20),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             _errorMessage,
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.email),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) return 'Please enter your email';
//                     if (!value.contains('@')) return 'Please enter a valid email';
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: const InputDecoration(
//                     labelText: 'Password',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.lock),
//                   ),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) return 'Please enter your password';
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _onLoginPressed,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Text(
//                           'Login',
//                           style: TextStyle(fontSize: 18),
//                         ),
//                 ),
//                 const SizedBox(height: 20),
//                 TextButton(
//                   onPressed: () {
//                     HapticFeedback.selectionClick();
//                     _showDemoUsers();
//                   },
//                   child: const Text('Demo Accounts'),
//                 ),
//                 const SizedBox(height: 30),
//                 const Row(
//                   children: [
//                     Expanded(child: Divider()),
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: Text('or'),
//                     ),
//                     Expanded(child: Divider()),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 OutlinedButton(
//                   onPressed: _onGuestPressed,
//                   child: const Text('Continue as Guest'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showDemoUsers() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Demo Accounts'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Try these credentials:'),
//             SizedBox(height: 10),
//             Text('• test@example.com / password123'),
//             SizedBox(height: 5),
//             Text('• user@demo.com / demo123'),
//             SizedBox(height: 10),
//             Text('Or create your own account!'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               HapticFeedback.selectionClick();
//               Navigator.pop(context);
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/auth_service.dart';
import '../main_nav/main_nav_page.dart';
import '../registration/registration_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color blue    = Color(0xFF1E88E5);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading     = false;
  bool _showPassword  = false;
  String _error       = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = ''; });
    HapticFeedback.mediumImpact();

    final error = await AuthService.instance.login(
      email:    _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _error = error);
      HapticFeedback.vibrate();
    } else {
      // Firebase authStateChanges in WelcomePage handles the redirect,
      // but we push directly for a snappier feel.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavPage()),
      );
    }
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above first.');
      return;
    }

    final error = await AuthService.instance.sendPasswordReset(email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Password reset email sent!'),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: grey900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to continue',
                style: TextStyle(fontSize: 15, color: grey600),
              ),
              const SizedBox(height: 32),

              // Error banner
              if (_error.isNotEmpty) _ErrorBanner(message: _error),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter your password';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sendReset,
                  child: const Text('Forgot password?',
                      style: TextStyle(color: blue, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 16),

              // Login button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Login',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // Go to register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?  ",
                      style: TextStyle(color: grey600)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegistrationScreen()),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                          color: blue, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Guest shortcut
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavPage()),
                  ),
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                        color: grey600,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared error banner ───────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}