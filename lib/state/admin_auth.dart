import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/admin_api.dart';

/// Status login panel admin (token + data user), dipersistensikan lokal.
class AdminAuth extends ChangeNotifier {
  static const _tokenKey = 'admin_token_v1';
  static const _userKey = 'admin_user_v1';

  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String get name => (_user?['name'] ?? 'Admin').toString();
  bool get isAdmin => _user?['is_admin'] == true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null) {
      _user = (jsonDecode(rawUser) as Map).cast<String, dynamic>();
    }
    if (_token != null) {
      AdminApi.token = _token;
    }
    notifyListeners();
  }

  Future<void> signIn(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    AdminApi.token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await AdminApi.logout();
    } catch (_) {
      // abaikan kegagalan jaringan saat keluar
    }
    _token = null;
    _user = null;
    AdminApi.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }
}
