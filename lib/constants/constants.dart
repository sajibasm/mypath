import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppConstants {
  // 🔹 Home location coordinates
  static const LatLng homeLatLng = LatLng(39.2904, -76.6122); // Example: Baltimore, MD

  // 🔹 Default map zoom
  static const double defaultZoom = 17.0;

  static const double defaultZoomHome = 11.0;

  // 🔹 Padding for Google Maps UI elements
  static const double mapPadding = 16.0;

  // 🔹 Default animation duration
  static const Duration animationDuration = Duration(milliseconds: 800);

  static const String accessToken = 'accessToken';
  static const String refreshToken = 'refreshToken';
  static const String accessTokenExp = 'access_exp';
  static const String refreshTokenExp = 'refresh_exp';

  static const double buttonVerticalPadding = 16.0;

}

class AppChartStyles {
  static const double chartHeight = 250.0;
  static const double axisTextSize = 12.0;
}
