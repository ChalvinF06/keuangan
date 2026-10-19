import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  static const String _hardcodedPassword = 'password9';

  bool _isLoggedIn = false;
  String _username = '';
  bool _isLoading = true;

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  bool get isLoading => _isLoading;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _username = prefs.getString(_keyUsername) ?? '';
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    if (password != _hardcodedPassword) return false;
    if (username.trim().isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username.trim());

    _isLoggedIn = true;
    _username = username.trim();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    _isLoggedIn = false;
    _username = '';
    notifyListeners();
  }
}