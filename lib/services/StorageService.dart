import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  static const String _wifiOnlyKey = 'wifiOnlyUpload'; // ✅ Define here
  static const _secureStorage = FlutterSecureStorage();
  static const _emailKey = 'biometric_email';
  static const _passwordKey = 'biometric_password';

  static Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  static Future<Map<String, String?>> loadCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    return {'email': email, 'password': password};
  }

  static Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
  }


  // ✅ Get Wi-Fi only upload setting
  static Future<bool> getWiFiOnlyUploadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wifiOnlyKey) ?? false;
  }

  // ✅ Set Wi-Fi only upload setting
  static Future<void> setWiFiOnlyUploadSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, value);
  }

  // ✅ Save selected wheelchair as JSON
  static Future<void> saveSelectedWheelchair(Map<String, dynamic> wheelchair) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_wheelchair', jsonEncode(wheelchair));
  }

// ✅ Load selected wheelchair
  static Future<Map<String, dynamic>?> loadSelectedWheelchair() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('selected_wheelchair');
    if (jsonString == null) return null;
    return jsonDecode(jsonString);
  }

  // ✅ Save tokens and expiration
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String accessExpires,
    required String refreshExpires,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('access_token_expires_at', accessExpires);
    await prefs.setString('refresh_token_expires_at', refreshExpires);
  }

  // ✅ Load tokens
  static Future<Map<String, String?>> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'access_token': prefs.getString('access_token'),
      'refresh_token': prefs.getString('refresh_token'),
      'access_token_expires_at': prefs.getString('access_token_expires_at'),
      'refresh_token_expires_at': prefs.getString('refresh_token_expires_at'),
    };
  }

  // ✅ Save user info
  static Future<void> saveUserInfo(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user['name']);
    await prefs.setString('user_email', user['email']);
    await prefs.setString('user_role', user['role']);
  }

  // ✅ Load user info
  static Future<Map<String, String?>> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'role': prefs.getString('user_role'),
    };
  }

  // ✅ Save tracking session
  static Future<void> saveRouteSession(Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('route_session', jsonEncode(session));
  }

// ✅ Load tracking session
  static Future<Map<String, dynamic>> getSavedRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('route_session');
    if (jsonString == null) return {};
    return jsonDecode(jsonString);
  }

// ✅ Clear tracking session
  static Future<void> clearRouteSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('route_session');
  }

  // ✅ Clear everything
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('access_token_expires_at');
    await prefs.remove('refresh_token_expires_at');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }
}
