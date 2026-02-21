import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthDatabase {
  static final AuthDatabase _instance = AuthDatabase._internal();
  factory AuthDatabase() => _instance;
  AuthDatabase._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _usersKey = 'local_link_users';
  final String _currentUserKey = 'local_link_current_user';

  // Hash password (basic security)
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Save user to secure storage
  Future<bool> saveUser(String username, String email, String password) async {
    try {
      final usersJson = await _secureStorage.read(key: _usersKey);
      Map<String, dynamic> users = {};
      
      if (usersJson != null) {
        users = Map<String, dynamic>.from(json.decode(usersJson));
      }

      // Check if user already exists
      if (users.containsKey(email)) {
        return false; // User already exists
      }

      // Create new user
      users[email] = {
        'username': username,
        'email': email,
        'password': _hashPassword(password), // Store hashed password
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save updated users
      await _secureStorage.write(
        key: _usersKey,
        value: json.encode(users),
      );

      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  // Authenticate user
  Future<Map<String, dynamic>?> authenticate(String email, String password) async {
    try {
      final usersJson = await _secureStorage.read(key: _usersKey);
      
      if (usersJson == null) return null;

      final users = Map<String, dynamic>.from(json.decode(usersJson));
      
      if (!users.containsKey(email)) return null;

      final user = users[email] as Map<String, dynamic>;
      final hashedPassword = _hashPassword(password);

      if (user['password'] == hashedPassword) {
        // Remove password from returned user data
        final userData = Map<String, dynamic>.from(user);
        userData.remove('password');
        
        // Save current user session
        await _saveCurrentSession(userData);
        
        return userData;
      }
      
      return null;
    } catch (e) {
      print('Error authenticating: $e');
      return null;
    }
  }

  // Save current session
  Future<void> _saveCurrentSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user));
  }

  // Get current user session
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      
      if (userJson == null) return null;
      
      return Map<String, dynamic>.from(json.decode(userJson));
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Check if user exists
  Future<bool> userExists(String email) async {
    try {
      final usersJson = await _secureStorage.read(key: _usersKey);
      if (usersJson == null) return false;
      
      final users = Map<String, dynamic>.from(json.decode(usersJson));
      return users.containsKey(email);
    } catch (e) {
      print('Error checking user: $e');
      return false;
    }
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    await _secureStorage.delete(key: _usersKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get all users (for debugging)
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final usersJson = await _secureStorage.read(key: _usersKey);
      if (usersJson == null) return {};
      
      return Map<String, dynamic>.from(json.decode(usersJson));
    } catch (e) {
      print('Error getting all users: $e');
      return {};
    }
  }
}