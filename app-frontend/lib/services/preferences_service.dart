import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_api.dart';

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const _kRememberEmail = 'remember_email';
  static const _kEmail = 'saved_email';
  static const _kRole = 'saved_role';
  static const _kDarkMode = 'dark_mode';
  static const _kUser = 'saved_user';

  Future<void> saveRemembered({required bool remember, String? email, String? role}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRememberEmail, remember);
    if (remember) {
      if (email != null) await p.setString(_kEmail, email);
      if (role != null) await p.setString(_kRole, role);
    } else {
      await p.remove(_kEmail);
      await p.remove(_kRole);
    }
  }

  Future<(bool remember, String? email, String? role)> loadRemembered() async {
    final p = await SharedPreferences.getInstance();
    final remember = p.getBool(_kRememberEmail) ?? false;
    final email = remember ? p.getString(_kEmail) : null;
    final role = remember ? p.getString(_kRole) : null;
    return (remember, email, role);
  }

  Future<void> setDarkMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDarkMode, value);
  }

  Future<bool> loadDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kDarkMode) ?? false;
  }

  Future<void> saveUser(AuthUser user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<AuthUser?> loadUser() async {
    final p = await SharedPreferences.getInstance();
    final userStr = p.getString(_kUser);
    if (userStr == null) return null;
    try {
      final map = jsonDecode(userStr) as Map<String, dynamic>;
      return AuthUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
