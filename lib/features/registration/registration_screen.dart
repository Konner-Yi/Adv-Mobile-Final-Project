// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../core/services/auth_database.dart';
// import '../main_nav/main_nav_page.dart';
//
// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({super.key});
//
//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }
//
// class _RegistrationScreenState extends State<RegistrationScreen> {
//   final AuthDatabase _authDatabase = AuthDatabase();
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   bool _isLoading = false;
//   String _errorMessage = '';
//   bool _showPassword = false;
//   bool _showConfirmPassword = false;
//
//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _register() async {
//     if (_formKey.currentState!.validate()) {
//       if (_passwordController.text != _confirmPasswordController.text) {
//         setState(() {
//           _errorMessage = 'Passwords do not match';
//         });
//         HapticFeedback.vibrate();
//         return;
//       }
//
//       setState(() {
//         _isLoading = true;
//         _errorMessage = '';
//       });
//
//       final username = _usernameController.text.trim();
//       final email = _emailController.text.trim();
//       final password = _passwordController.text.trim();
//
//       final success = await _authDatabase.saveUser(username, email, password);
//
//       if (success) {
//         final user = await _authDatabase.authenticate(email, password);
//
//         if (user != null) {
//           HapticFeedback.mediumImpact();
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const MainNavPage(),
//             ),
//           );
//         } else {
//           setState(() {
//             _isLoading = false;
//             _errorMessage =
//                 'Account created but login failed. Please login manually.';
//           });
//           HapticFeedback.vibrate();
//         }
//       } else {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Email already exists';
//         });
//         HapticFeedback.vibrate();
//       }
//     } else {
//       HapticFeedback.vibrate();
//     }
//   }
//
//   void _onCreateAccountPressed() {
//     HapticFeedback.mediumImpact();
//     _register();
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
//             Navigator.pop(context);
//           },
//         ),
//         title: const Text('Create Account'),
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
//                   'Join Local Link',
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   'Create your account to start discovering',
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
//                         const Icon(Icons.error_outline,
//                             color: Colors.red, size: 20),
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
//                   controller: _usernameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Username',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.person),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a username';
//                     }
//                     if (value.length < 3) {
//                       return 'Username must be at least 3 characters';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.email),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     if (!value.contains('@')) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: InputDecoration(
//                     labelText: 'Password',
//                     border: const OutlineInputBorder(),
//                     prefixIcon: const Icon(Icons.lock),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                           _showPassword ? Icons.visibility : Icons.visibility_off),
//                       onPressed: () {
//                         HapticFeedback.selectionClick();
//                         setState(() => _showPassword = !_showPassword);
//                       },
//                     ),
//                   ),
//                   obscureText: !_showPassword,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a password';
//                     }
//                     if (value.length < 6) {
//                       return 'Password must be at least 6 characters';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),
//                 TextFormField(
//                   controller: _confirmPasswordController,
//                   decoration: InputDecoration(
//                     labelText: 'Confirm Password',
//                     border: const OutlineInputBorder(),
//                     prefixIcon: const Icon(Icons.lock_outline),
//                     suffixIcon: IconButton(
//                       icon: Icon(_showConfirmPassword
//                           ? Icons.visibility
//                           : Icons.visibility_off),
//                       onPressed: () {
//                         HapticFeedback.selectionClick();
//                         setState(() =>
//                             _showConfirmPassword = !_showConfirmPassword);
//                       },
//                     ),
//                   ),
//                   obscureText: !_showConfirmPassword,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please confirm your password';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _onCreateAccountPressed,
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
//                           'Create Account',
//                           style: TextStyle(fontSize: 18),
//                         ),
//                 ),
//                 const SizedBox(height: 30),
//                 const Text(
//                   'By registering, you agree to our Terms of Service and Privacy Policy',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 12, color: Colors.grey),
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
import 'package:flutter/services.dart';

import '../../core/services/auth_service.dart';
import '../main_nav/main_nav_page.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const Color blue    = Color(0xFF1E88E5);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  final _formKey                  = GlobalKey<FormState>();
  final _usernameController       = TextEditingController();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading          = false;
  bool _showPassword       = false;
  bool _showConfirmPassword = false;
  String _error            = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      HapticFeedback.vibrate();
      return;
    }

    setState(() { _isLoading = true; _error = ''; });
    HapticFeedback.mediumImpact();

    final error = await AuthService.instance.register(
      username: _usernameController.text,
      email:    _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _error = error);
      HapticFeedback.vibrate();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavPage()),
      );
    }
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
        title: const Text('Create Account'),
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
                'Join Local Link',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: grey900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your account to start discovering',
                style: TextStyle(fontSize: 15, color: grey600),
              ),
              const SizedBox(height: 32),

              // Error banner
              if (_error.isNotEmpty) _ErrorBanner(message: _error),

              // Username
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter a username';
                  if (v.trim().length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

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
                textInputAction: TextInputAction.next,
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
                  if (v == null || v.isEmpty) return 'Please enter a password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _register(),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Register button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Create Account',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'By registering you agree to our Terms of Service\nand Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: grey600),
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