import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';

class AuthService {
  static final _storage = const FlutterSecureStorage();

  /// ✅ Check if access token is still valid
  static Future<bool> isAccessTokenValid() async {
    final token = await _storage.read(key: AppConstants.accessToken);
    final expString = await _storage.read(key: AppConstants.accessTokenExp);

    if (token == null || expString == null) return false;

    final exp = int.tryParse(expString);
    if (exp == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now < exp;
  }
}
