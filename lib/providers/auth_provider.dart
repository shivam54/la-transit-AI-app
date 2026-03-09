import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyUserId = 'auth_user_id';
  static const _keyUsername = 'auth_username';
  static const _keyLastUserId = 'auth_last_user_id';
  static const _keyLastUsername = 'auth_last_username';

  String? _userId;
  String? _username;
  String? _lastUserId;
  String? _lastUsername;
  bool _initialized = false;

  String? get userId => _userId;
  String? get username => _username;
  String? get lastUserId => _lastUserId;
  String? get lastUsername => _lastUsername;
  bool get isLoggedIn => _userId != null;
  bool get isInitialized => _initialized;

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_keyUserId);
    _username = prefs.getString(_keyUsername);
    _lastUserId = prefs.getString(_keyLastUserId);
    _lastUsername = prefs.getString(_keyLastUsername);

    // If there is a current user but no "last" data yet, seed it.
    if (_userId != null && _username != null) {
      _lastUserId ??= _userId;
      _lastUsername ??= _username;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setUser(String userId, String username) async {
    _userId = userId;
    _username = username;
    _lastUserId = userId;
    _lastUsername = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyLastUserId, userId);
    await prefs.setString(_keyLastUsername, username);
    notifyListeners();
  }

  Future<void> logout() async {
    _userId = null;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    // Intentionally keep _lastUserId/_lastUsername so we can offer quick re‑login.
    notifyListeners();
  }
}
