import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
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
