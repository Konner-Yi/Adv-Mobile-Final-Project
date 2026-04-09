import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth      _auth    = FirebaseAuth.instance;
  final FirebaseFirestore _db      = FirebaseFirestore.instance;
  final FirebaseStorage   _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool  get isLoggedIn  => _auth.currentUser != null;

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(username.trim());

      await _db.collection('users').doc(uid).set({
        'uid':        uid,
        'username':   username.trim(),
        'email':      email.trim().toLowerCase(),
        'createdAt':  FieldValue.serverTimestamp(),
        'score':      0,
        'followers':  0,
        'following':  0,
        'bio':        '',
        'realName':   '',
        'pronouns':   '',
        'country':    '',
        'tags':       <String>[],
        'photoUrl':   '',

        // 🔥 ONLY ADDITION (nothing else changed)
        'latitude':   null,
        'longitude':  null,
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Stream<Map<String, dynamic>?> getUserProfileStream() {
    final uid = currentUser?.uid;
    print('[AuthService] getUserProfileStream uid: $uid'); // <-- debug
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      print('[AuthService] snapshot data: ${doc.data()}'); // <-- debug
      return doc.exists ? doc.data() : null;
    });
  }

  Future<void> updateUserProfile(Map<String, dynamic> fields) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update(fields);

    if (fields.containsKey('username')) {
      await currentUser!.updateDisplayName(fields['username'] as String);
    }
  }

  Future<String?> uploadProfilePhoto(File imageFile) async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    try {
      final ref = _storage.ref('profile_photos/$uid.jpg');

      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();

      await _db.collection('users').doc(uid).update({'photoUrl': url});
      await currentUser!.updatePhotoURL(url);

      return url;
    } catch (_) {
      return null;
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong ($code).';
    }
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// /// Wraps Firebase Auth + Firestore user-profile operations.
// /// Drop this file at lib/core/services/auth_service.dart
// /// and delete (or keep for reference) the old auth_database.dart.
// class AuthService {
//   AuthService._();
//   static final AuthService instance = AuthService._();
//
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   // ── Stream ────────────────────────────────────────────────────────────────
//
//   /// Listen to auth state changes throughout the app.
//   Stream<User?> get authStateChanges => _auth.authStateChanges();
//
//   // ── Current user ─────────────────────────────────────────────────────────
//
//   User? get currentUser => _auth.currentUser;
//
//   bool get isLoggedIn => _auth.currentUser != null;
//
//   // ── Sign up ───────────────────────────────────────────────────────────────
//
//   /// Creates a Firebase Auth account and writes a Firestore user document.
//   /// Returns null on success, or an error message string on failure.
//   Future<String?> register({
//     required String username,
//     required String email,
//     required String password,
//   }) async {
//     try {
//       // 1. Create the auth account
//       final credential = await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password,
//       );
//
//       final uid = credential.user!.uid;
//
//       // 2. Update the Firebase Auth display name
//       await credential.user!.updateDisplayName(username.trim());
//
//       // 3. Write the user profile document to Firestore
//       await _db.collection('users').doc(uid).set({
//         'uid': uid,
//         'username': username.trim(),
//         'email': email.trim().toLowerCase(),
//         'createdAt': FieldValue.serverTimestamp(),
//         'score': 0,
//         'followers': 0,
//         'following': 0,
//         'bio': '',
//         'country': '',
//         'pronouns': '',
//         'tags': <String>[],
//       });
//
//       return null; // success
//     } on FirebaseAuthException catch (e) {
//       return _friendlyError(e.code);
//     } catch (e) {
//       return 'Something went wrong. Please try again.';
//     }
//   }
//
//   // ── Sign in ───────────────────────────────────────────────────────────────
//
//   /// Returns null on success, or an error message string on failure.
//   Future<String?> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password,
//       );
//       return null; // success
//     } on FirebaseAuthException catch (e) {
//       return _friendlyError(e.code);
//     } catch (e) {
//       return 'Something went wrong. Please try again.';
//     }
//   }
//
//   // ── Sign out ──────────────────────────────────────────────────────────────
//
//   Future<void> logout() => _auth.signOut();
//
//   // ── Password reset ────────────────────────────────────────────────────────
//
//   /// Sends a password-reset email. Returns null on success or an error string.
//   Future<String?> sendPasswordReset(String email) async {
//     try {
//       await _auth.sendPasswordResetEmail(email: email.trim());
//       return null;
//     } on FirebaseAuthException catch (e) {
//       return _friendlyError(e.code);
//     }
//   }
//
//   // ── Firestore helpers ─────────────────────────────────────────────────────
//
//   /// Fetches the Firestore profile document for the current user.
//   Future<Map<String, dynamic>?> getUserProfile() async {
//     final uid = currentUser?.uid;
//     if (uid == null) return null;
//     final doc = await _db.collection('users').doc(uid).get();
//     return doc.exists ? doc.data() : null;
//   }
//
//   /// Updates fields in the current user's Firestore document.
//   Future<void> updateUserProfile(Map<String, dynamic> fields) async {
//     final uid = currentUser?.uid;
//     if (uid == null) return;
//     await _db.collection('users').doc(uid).update(fields);
//   }
//
//   // ── Friendly error messages ───────────────────────────────────────────────
//
//   String _friendlyError(String code) {
//     switch (code) {
//       case 'email-already-in-use':
//         return 'An account with this email already exists.';
//       case 'invalid-email':
//         return 'Please enter a valid email address.';
//       case 'weak-password':
//         return 'Password must be at least 6 characters.';
//       case 'user-not-found':
//       case 'wrong-password':
//       case 'invalid-credential':
//         return 'Incorrect email or password.';
//       case 'user-disabled':
//         return 'This account has been disabled.';
//       case 'too-many-requests':
//         return 'Too many attempts. Please try again later.';
//       case 'network-request-failed':
//         return 'No internet connection.';
//       default:
//         return 'Something went wrong ($code).';
//     }
//   }
// }