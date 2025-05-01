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
  static bool get hasToken => _token != null && _token!.isNotEmpty;

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

  static Future<dynamic> _handleAuthAndRetry(Future<http.Response> Function() requestFn) async {
    try {
      return await _retryRequest(requestFn);
    } on http.ClientException catch (e) {
      if (e.message.contains('401') && await _tryRefreshToken()) {
        return await _retryRequest(requestFn); // Retry after refresh
      }
      rethrow;
    }
  }

  static Future<bool> _tryRefreshToken() async {
    final refresh = await _storage.read(key: AppConstants.refreshToken);
    if (refresh == null) return false;

    final response = await http.post(AppEndpoints.tokenRefresh,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      await setToken(decoded['access']);
      return true;
    }

    return false;
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

  static Future<dynamic> createTransitMarker({
    required String transitId,
    required int segmentNumber,
    required String markerCategory,
    required String markerType,
    required double markerLat,
    required double markerLng,
  }) async {
    try {
      final data = {
        "transit_id": transitId,
        "segment_number": segmentNumber,
        "marker_category": markerCategory,
        "marker_type": markerType,
        "marker_lat": markerLat,
        "marker_lng": markerLng,
      };

      print('[Marker API] Sending marker: $data');

      final response = await post(AppEndpoints.markerCreate, data);

      print('[Marker API] Response: $response');

      return response;
    } catch (e) {
      print('[Marker API] Error: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> searchMarkers({
    required double marker_lat,
    required double marker_lng,
  }) async {
    try {
      final data = {
        "marker_lat": marker_lat,
        "marker_lng": marker_lng,
      };

      print('[Marker Search API] Request: $data');

      final response = await post(AppEndpoints.markerSearch, data);

      print('[Marker Search API] Response: $response');

      // 🔥 Ensure list
      if (response is List) {
        return response;
      } else if (response is Map && response.containsKey('latitude') && response.containsKey('longitude')) {
        return [response]; // Wrap in a list
      } else {
        return [];
      }
    } catch (e) {
      print('[Marker Search API] Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> updateMarkerStatus({
    required double marker_lat,
    required double marker_lng,
    required double segmentEndLat,
    required double segmentEndLng,
    required String status, // e.g., 'resolved', 'ignored'
  }) async {
    try {
      final data = {
        "marker_lat": marker_lat,
        "marker_lng": marker_lng,
        "status": status,
      };

      print('[Marker Update API] Request: $data');

      final response = await post(AppEndpoints.markerUpdate, data);

      print('[Marker Update API] Response: $response');

      return response;
    } catch (e) {
      print('[Marker Update API] Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> createTransit({
    required String transitId,
    required int wheelChair, // Usually 0 or 1
  }) async {
    try {
      final data = {
        "transit_id": transitId,
        "wheel_chair": wheelChair,
      };

      print('[Transit Create API] Request: $data');

      final response = await post(AppEndpoints.transitCreate, data);

      print('[Transit Create API] Response: $response');

      return response;
    } catch (e) {
      print('[Transit Create API] Error: $e');
      rethrow;
    }
  }

  /// ✅ Complete Transit with distance and duration
  static Future<dynamic> completeTransit({
    required String transitId,
    required double distance,
    required double duration,
  }) async {
    try {
      final data = {
        "transit_id": transitId,
        "distance": distance.toString(), // API expects distance as string
        "duration": duration,            // API accepts duration as numeric
      };

      print('[Transit Complete API] Request: $data');

      final response = await put(AppEndpoints.transitComplete, data);

      print('[Transit Complete API] Response: $response');

      return response;
    } catch (e) {
      print('[Transit Complete API] Error: $e');
      rethrow;
    }
  }


  /// ❌ Cancel Transit by ID
  static Future<dynamic> cancelTransit({
    required String transitId,
    required double distance,
    required double duration,
  }) async {
    try {
      final data = {
        "transit_id": transitId,
        "distance": distance.toString(), // 🔐 Send as string
        "duration": duration,            // 🔐 Send as numeric
      };

      print('[Transit Cancel API] Request: $data');

      final response = await put(AppEndpoints.transitCancel, data);

      print('[Transit Cancel API] Response: $response');

      return response;
    } catch (e) {
      print('[Transit Cancel API] Error: $e');
      rethrow;
    }
  }


  /// 🔐 LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await clearToken();

      final response = await post(AppEndpoints.login, {
        'email': email,
        'password': password,
      });

      if (response['token'] != null) {
        final access = response['token']['access'];
        final refresh = response['token']['refresh'];
        final accessExp = response['token']['access_exp']?.toString();  // Save as string
        final refreshExp = response['token']['refresh_exp']?.toString();

        // ✅ Store all token info securely
        await setToken(access);
        await _storage.write(key: AppConstants.refreshToken, value: refresh);

        if (accessExp != null) {
          await _storage.write(key: AppConstants.accessTokenExp, value: accessExp);
        }

        if (refreshExp != null) {
          await _storage.write(key: AppConstants.refreshTokenExp, value: refreshExp);
        }

        return {
          'access': access,
          'refresh': refresh,
          'access_exp': accessExp,
          'refresh_exp': refreshExp,
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


  /// 🌐 Call Route API without using LatLng
  static Future<dynamic> routes({
    required String origin,
    required String destination,
  }) async {
    try {
      final data = {
        "originLocation": origin,
        "destinationLocation": destination,
      };


      final response = await post(AppEndpoints.routeSearch, data);
      // print('[Route API] Success: $response');

      return response;
    } catch (e) {
      print('[Route API] Error: $e');
      rethrow;
    }
  } // 👈 You missed closing this brace
} // 👈 Closing brace of ApiService class itself


