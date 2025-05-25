import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';
import '../constants/endpoints.dart';
import 'StorageService.dart';

class ApiService {
  static const Duration timeoutDuration = Duration(seconds: 10);
  static String? _token; // 🔐 Bearer token used globally
  static const _storage = FlutterSecureStorage();

  static bool get hasToken => _token != null && _token!.isNotEmpty;

  /// 🔐 Sets the access token in memory and secure storage
  static Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: AppConstants.accessToken, value: token);
  }

  /// 🔐 Loads the access token from secure storage into memory
  static Future<void> loadToken() async {
    _token = await _storage.read(key: AppConstants.accessToken);
  }

  /// 🔐 Clears both access and refresh tokens from memory and storage
  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: AppConstants.accessToken);
    await _storage.delete(key: AppConstants.refreshToken);
  }

  /// 🔄 Handles token refresh on 401 and retries request
  static Future<http.Response> _authorizedRequestWithRetry(
    Future<http.Response> Function(String token) requestFn,
  ) async {
    final tokens = await StorageService.loadTokens();
    String? accessToken = tokens['access_token'];

    if (accessToken == null) throw Exception('Access token not found.');

    http.Response response = await requestFn(accessToken);
    if (response.statusCode != 401) return response;

    print("looking for refreshToken");

    bool refreshed = await refreshToken();
    if (!refreshed) throw Exception('Session expired. Please login again.');

    final newTokens = await StorageService.loadTokens();
    accessToken = newTokens['access_token'];

    return await requestFn(accessToken!);
  }

  /// 📍 Refreshes the access token using the refresh token
  static Future<bool> refreshToken() async {
    final tokens = await StorageService.loadTokens();
    final refreshToken = tokens['refresh_token'];

    if (refreshToken == null) return false;

    final response = await http.post(
      AppApi.refresh, // example: /api/user/token/refresh/
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await StorageService.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        accessExpires: data['access_token_expires_at'],
        refreshExpires: data['refresh_token_expires_at'],
      );
      return true;
    }

    return false;
  }

  /// 📍 Sends a password reset code to the user's email
  static Future<Map<String, dynamic>> sendPasswordResetCode(
    String email,
  ) async {
    try {
      final response = await http.post(
        AppApi.resetPasswordSendCode,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      return {'status': data['status'], 'detail': data['detail']};
    } catch (e) {
      return {'status': false, 'detail': 'Exception: $e'};
    }
  }

  /// 📍 Verifies the OTP code for password reset
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String code,
  ) async {
    try {
      final response = await http.post(
        AppApi.resetPasswordVerifyCode,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final data = jsonDecode(response.body);
      return {'status': data['status'], 'detail': data['detail']};
    } catch (e) {
      return {'status': false, 'detail': 'Exception: $e'};
    }
  }

  /// 📍 Resets the user's password using the provided email, code, and new password
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        AppApi.resetPasswordConfirm,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      return {'status': data['status'], 'detail': data['detail']};
    } catch (e) {
      return {'status': false, 'detail': 'Exception: $e'};
    }
  }

  // /// 📍 Fetches the user's profile information
  /// 👤 Fetches user profile with token refresh logic
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _authorizedRequestWithRetry(
        (token) => http.get(
          AppApi.profile,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'status': true, 'profile': data};
      } else {
        return {
          'status': false,
          'detail': 'Failed to load profile. Code: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('[Profile API] Error: $e');
      return {'status': false, 'detail': 'Exception: $e'};
    }
  }

  // /// 📍 Updates the user's profile information
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String height,
    required String weight,
    required String gender,
    required String age,
  }) async {
    final tokens = await StorageService.loadTokens();
    final accessToken = tokens['access_token'];

    if (accessToken == null) {
      return {'status': false, 'detail': 'Access token not found.'};
    }

    final response = await _authorizedRequestWithRetry(
      (token) => http.put(
        AppApi.profileUpdate,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'height': height,
          'weight': weight,
          'gender': gender,
          'age': age,
        }),
      ),
    );

    final data = jsonDecode(response.body);
    return {'status': response.statusCode == 200, ...data};
  }

  // /// 📍 Signs up a new user with email and password
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String name,
    required String password,
    required String height,
    required String weight,
    required String gender,
    required String age,
    required bool termsCondition,
  }) async {
    try {
      final response = await http.post(
        AppApi.register,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'password': password,
          'terms_condition': termsCondition.toString(),
          'height': height,
          'weight': weight,
          'gender': gender,
          'age': age,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': true,
          'detail': 'Signup successful.',
          'user': data['user'],
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'access_token_expires_at': data['access_token_expires_at'],
          'refresh_token_expires_at': data['refresh_token_expires_at'],
        };
      } else {
        return {
          'status': false,
          'detail': data['email']?[0] ?? data['detail'] ?? 'Signup failed.',
        };
      }
    } catch (e) {
      return {'status': false, 'detail': 'Exception: $e'};
    }
  }

  // /// 📍 Logs in a user with email and password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        AppApi.login,
        // Example: Uri.parse('https://your-api.com/api/user/login/')
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      // print('Login failed response: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'status': true,
          'detail': 'Login successful.',
          'user': data['user'],
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'access_token_expires_at': data['access_token_expires_at'],
          'refresh_token_expires_at': data['refresh_token_expires_at'],
        };
      } else {
        return {
          'status': false,
          'detail': data['detail'] ??
              (data['non_field_errors'] is List
                  ? data['non_field_errors'].join(', ')
                  : 'Login failed.')
        };
      }
    } catch (e) {
      return {'status': false, 'detail': 'Exception: $e'};
    }
  }

  // /// 📍 Changes the user's password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _authorizedRequestWithRetry(
      (token) => http.post(
        AppApi.changePassword,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': currentPassword,
          'new_password': newPassword,
        }),
      ),
    );

    final data = jsonDecode(response.body);
    return {'status': response.statusCode == 200, ...data};
  }

  // /// 📍 Fetches the list of wheelchairs for the user
  static Future<List<dynamic>> getUserWheelchairs() async {
    try {
      final response = await _authorizedRequestWithRetry(
            (token) => http.get(
          AppApi.userWheelChair,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results'] ?? [];
      } else {
        throw Exception("Failed to load wheelchairs: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Wheelchair fetch error: $e");
      throw Exception("Session expired. Please login again.");
    }
  }

  /// 📍 Creates a new wheelchair
  static Future<void> createWheelchair(Map<String, dynamic> data) async {
    final response = await _authorizedRequestWithRetry(
      (token) => http.post(
        AppApi.userWheelChair,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to create wheelchair');
    }
  }

  /// 📍 Updates an existing wheelchair
  static Future<void> updateWheelchair(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _authorizedRequestWithRetry(
      (token) => http.put(
        Uri.parse('${AppApi.userWheelChair}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to update wheelchair');
    }
  }

  /// 📍 Patches an existing wheelchair
  static Future<void> patchWheelchair(int id, Map<String, dynamic> data) async {
    final response = await _authorizedRequestWithRetry(
      (token) => http.patch(
        Uri.parse('${AppApi.userWheelChair}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to update wheelchair: ${response.body}');
    }
  }

  /// 📍 Fetches wheelchair types
  static Future<List<dynamic>> getWheelchairTypes() async {
    final response = await _authorizedRequestWithRetry(
      (token) => http.get(
        AppApi.wheelChairType,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );
    return jsonDecode(response.body)['results'];
  }

  // 📍 Fetches wheelchair drive types
  static Future<List<dynamic>> getDriveTypes() async {
    final response = await _authorizedRequestWithRetry(
      (token) => http.get(
        AppApi.wheelChairDriveType,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    return jsonDecode(response.body)['results'];
  }

  /// 📍 Fetches wheelchair tire materials
  static Future<List<dynamic>> getTireMaterials() async {
    final response = await _authorizedRequestWithRetry(
      (token) => http.get(
        AppApi.wheelChairTireMaterial,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    return jsonDecode(response.body)['results'];
  }

  /// 📍 Fetches routes between two locations
  static Future<dynamic> routes({
    required String origin,
    required String destination,
  }) async {
    try {
      final response = await _authorizedRequestWithRetry(
        (token) => http.post(
          AppApi.routeSearch,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "originLocation": origin,
            "destinationLocation": destination,
          }),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body);
        print('[Route API] Success: $result');
        return result;
      } else {
        print('[Route API] Failed with code: ${response.statusCode}');
        throw Exception('Failed to fetch route: ${response.body}');
      }
    } catch (e) {
      print('[Route API] Exception: $e');
      rethrow;
    }
  }

  /// 📍 Creates a new transit marker (barrier/facility report)
  static Future<dynamic> createTransitMarker({
    required String transitId,
    required int segmentNumber,
    required String markerCategory,
    required String markerType,
    required double markerLat,
    required double markerLng,
  }) async {
    try {
      final response = await _authorizedRequestWithRetry(
        (token) => http.post(
          AppApi.markerCreate,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "transit_id": transitId,
            "segment_number": segmentNumber,
            "marker_category": markerCategory,
            "marker_type": markerType,
            "marker_lat": markerLat,
            "marker_lng": markerLng,
          }),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body);
        print('[Marker API] Success: $result');
        return result;
      } else {
        print('[Marker API] Failed with code: ${response.statusCode}');
        throw Exception('Failed to create marker: ${response.body}');
      }
    } catch (e) {
      print('[Marker API] Exception: $e');
      rethrow;
    }
  }

  /// ✏️ Updates the status of a transit marker (e.g., resolved or ignored)
  static Future<List<dynamic>> searchMarkers({
    required double marker_lat,
    required double marker_lng,
  }) async {
    try {
      final response = await _authorizedRequestWithRetry(
        (token) => http.post(
          AppApi.markerSearch,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "marker_lat": marker_lat,
            "marker_lng": marker_lng,
          }),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        print('[Marker Search API] Response: $data');

        // 🔥 Ensure list
        if (data is List) {
          return data;
        } else if (data is Map &&
            data.containsKey('latitude') &&
            data.containsKey('longitude')) {
          return [data]; // Wrap single marker in a list
        } else {
          return [];
        }
      } else {
        print('[Marker Search API] Failed with code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[Marker Search API] Error: $e');
      rethrow;
    }
  }

  // 🔄 Updates the status of a transit marker (e.g., resolved, ignored)
  static Future<dynamic> updateMarkerStatus({
    required double marker_lat,
    required double marker_lng,
    required double segmentEndLat, // currently unused in payload
    required double segmentEndLng, // currently unused in payload
    required String status, // e.g., 'resolved', 'ignored'
  }) async {
    try {
      final response = await _authorizedRequestWithRetry(
        (token) => http.post(
          AppApi.markerUpdate,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "marker_lat": marker_lat,
            "marker_lng": marker_lng,
            "status": status,
          }),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body);
        print('[Marker Update API] Success: $result');
        return result;
      } else {
        print('[Marker Update API] Failed with code: ${response.statusCode}');
        throw Exception('Failed to update marker: ${response.body}');
      }
    } catch (e) {
      print('[Marker Update API] Exception: $e');
      rethrow;
    }
  }

  // 📦 Creates a new transit (e.g., for a wheelchair user)
  static Future<dynamic> createTransit({
    required String transitId,
    required int wheelChair, // Usually 0 or 1
  }) async {
    try {
      final response = await _authorizedRequestWithRetry(
        (token) => http.post(
          AppApi.transitCreate,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'transit_id': transitId,
            'wheel_chair': wheelChair,
          }),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body);
        print('[Transit Create API] Success: $result');
        return result;
      } else {
        print('[Transit Create API] Error Code: ${response.statusCode}');
        throw Exception('Failed to create transit: ${response.body}');
      }
    } catch (e) {
      print('[Transit Create API] Exception: $e');
      rethrow;
    }
  }

  // 📦 Completes an ongoing transit (e.g., after reaching destination)
  static Future<dynamic> completeTransit({
    required String transitId,
    required double distance,
    required double duration,
  }) async {
    try {
      final response = await _authorizedRequestWithRetry(
        (token) => http.put(
          AppApi.transitComplete,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "transit_id": transitId,
            "distance": distance.toString(), // Ensure distance is a string
            "duration": duration,
          }),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body);
        print('[Transit Complete API] Success: $result');
        return result;
      } else {
        print('[Transit Complete API] Error: ${response.statusCode}');
        throw Exception('Failed to complete transit: ${response.body}');
      }
    } catch (e) {
      print('[Transit Complete API] Exception: $e');
      rethrow;
    }
  }

  // 📦 Cancels an ongoing transit (e.g., if user decides to stop)
  static Future<dynamic> cancelTransit({
    required String transitId,
    required double distance,
    required double duration,
  }) async {
    try {
      final response = await _authorizedRequestWithRetry(
        (token) => http.put(
          AppApi.transitCancel,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "transit_id": transitId,
            "distance": distance.toString(), // String as required
            "duration": duration, // Numeric
          }),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body);
        print('[Transit Cancel API] Success: $result');
        return result;
      } else {
        print('[Transit Cancel API] Error Code: ${response.statusCode}');
        throw Exception('Failed to cancel transit: ${response.body}');
      }
    } catch (e) {
      print('[Transit Cancel API] Exception: $e');
      rethrow;
    }
  }
}
