import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';
import '../constants/endpoints.dart';

class ApiService {
  static const Duration timeoutDuration = Duration(seconds: 10);
  static String? _token; // 🔐 Bearer token used globally
  static const _storage = FlutterSecureStorage();

  /// 🔐 Set the token and cache it in memory
  static Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: AppConstants.accessToken, value: token);
  }

  /// 🔐 Load token from secure storage
  static Future<void> loadToken() async {
    _token = await _storage.read(key: AppConstants.accessToken);
  }

  /// 🔐 Clear token from both memory and storage
  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: AppConstants.accessToken);
    await _storage.delete(key: AppConstants.refreshToken);
  }

  /// 📦 Common headers with optional authorization
  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// 🔁 Retry wrapper
  static Future<http.Response> _retryRequest(
      Future<http.Response> Function() requestFn, {
        int retries = 2,
      }) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        final response = await requestFn().timeout(timeoutDuration);
        return response;
      } catch (e) {
        attempt++;
        if (attempt >= retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
    throw Exception("Request failed after $retries retries");
  }

  /// 🔧 Response handler
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw HttpException(
        'Error ${response.statusCode}: ${response.reasonPhrase}',
        uri: response.request?.url,
      );
    }
  }

  /// 🌐 GET
  static Future<dynamic> get(Uri uri) async {
    try {
      final response = await _retryRequest(() => http.get(uri, headers: _headers()));
      return _handleResponse(response);
    } catch (e) {
      print('[GET ERROR] $e');
      rethrow;
    }
  }

  /// 🌐 POST
  static Future<dynamic> post(Uri uri, Map<String, dynamic> data) async {
    try {
      final response = await _retryRequest(() => http.post(
        uri,
        headers: _headers(),
        body: jsonEncode(data),
      ));
      return _handleResponse(response);
    } catch (e) {
      print('[POST ERROR] $e');
      rethrow;
    }
  }

  /// 🌐 PUT
  static Future<dynamic> put(Uri uri, Map<String, dynamic> data) async {
    try {
      final response = await _retryRequest(() => http.put(
        uri,
        headers: _headers(),
        body: jsonEncode(data),
      ));
      return _handleResponse(response);
    } catch (e) {
      print('[PUT ERROR] $e');
      rethrow;
    }
  }

  /// 🌐 DELETE
  static Future<void> delete(Uri uri) async {
    try {
      final response = await _retryRequest(() => http.delete(uri, headers: _headers()));
      _handleResponse(response);
    } catch (e) {
      print('[DELETE ERROR] $e');
      rethrow;
    }
  }

  /// 🔐 LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await post(AppEndpoints.login, {
        'email': email,
        'password': password,
      });

      if (response['token'] != null) {
        final access = response['token']['access'];
        final refresh = response['token']['refresh'];

        // ✅ Store both tokens securely
        await setToken(access);
        await _storage.write(key: AppConstants.refreshToken, value: refresh);

        return {
          'access': access,
          'refresh': refresh,
          'msg': response['msg'] ?? 'Login successful',
        };
      } else {
        throw Exception('Invalid token structure in response');
      }
    } catch (e) {
      print('[LOGIN ERROR] $e');
      rethrow;
    }
  }

  static bool get hasToken => _token != null && _token!.isNotEmpty;

}
