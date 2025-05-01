import 'constants.dart';

class AppEndpoints {
  static const String apiBaseUrl = 'https://a45c-2600-4040-b5e5-f300-5d3-acbc-2c91-a63f.ngrok-free.app';

  // User profile
  static final Uri login = Uri.parse('$apiBaseUrl/api/user/login/');
  static final Uri tokenRefresh = Uri.parse('$apiBaseUrl/api/user/tokenRefresh/');
  static final Uri register = Uri.parse('$apiBaseUrl/api/user/register/');
  static final Uri refresh = Uri.parse('$apiBaseUrl/api/user/refresh/');
  static final Uri profile = Uri.parse('$apiBaseUrl/api/user/profile/');

  // Navigation (NEW)
  static final Uri routeSearch = Uri.parse('$apiBaseUrl/api/navigation/route/');

  // Transit Routes
  static final Uri transitCreate = Uri.parse('$apiBaseUrl/api/navigation/transits/create/');
  static final Uri transitCancel = Uri.parse('$apiBaseUrl/api/navigation/transits/cancel/');
  static final Uri transitComplete = Uri.parse('$apiBaseUrl/api/navigation/transits/complete/');

  // Marker Routes
  static final Uri markerCreate = Uri.parse('$apiBaseUrl/api/navigation/markers/create/');
  static final Uri markerSearch = Uri.parse('$apiBaseUrl/api/navigation/markers/search/');
  static final Uri markerUpdate = Uri.parse('$apiBaseUrl/api/navigation/markers/update/');
}
