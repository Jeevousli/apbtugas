import 'package:shared_preferences/shared_preferences.dart';

/// Handles local persistence for auth (Remember Me, saved credentials).
class AuthLocalDataSource {
  final SharedPreferences _prefs;

  AuthLocalDataSource(this._prefs);

  static const _keyRememberMe = 'remember_me';
  static const _keySavedIdentifier = 'saved_identifier';
  static const _keyLoginMode = 'login_mode'; // 'email' or 'nik'
  static const _keyIsLoggedIn = 'is_logged_in';

  // ─────────────────────── REMEMBER ME ────────────────────────────
  Future<void> saveRememberMe({
    required bool rememberMe,
    required String identifier,
    required String loginMode,
  }) async {
    await _prefs.setBool(_keyRememberMe, rememberMe);
    if (rememberMe) {
      await _prefs.setString(_keySavedIdentifier, identifier);
      await _prefs.setString(_keyLoginMode, loginMode);
    } else {
      await _prefs.remove(_keySavedIdentifier);
      await _prefs.remove(_keyLoginMode);
    }
  }

  bool get isRememberMe => _prefs.getBool(_keyRememberMe) ?? false;
  String get savedIdentifier => _prefs.getString(_keySavedIdentifier) ?? '';
  String get savedLoginMode => _prefs.getString(_keyLoginMode) ?? 'email';

  // ─────────────────────── LOGIN STATE ────────────────────────────
  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
  }

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;

  // ─────────────────────── CLEAR ──────────────────────────────────
  Future<void> clearAuthData() async {
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyRememberMe);
    await _prefs.remove(_keySavedIdentifier);
    await _prefs.remove(_keyLoginMode);
  }
}
