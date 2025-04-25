import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppConstants {
  // 🔹 Home location coordinates
  static const LatLng homeLatLng = LatLng(39.2904, -76.6122); // Example: Baltimore, MD

  // 🔹 Default map zoom
  static const double defaultZoom = 14.0;

  // 🔹 Padding for Google Maps UI elements
  static const double mapPadding = 16.0;

  // 🔹 Default animation duration
  static const Duration animationDuration = Duration(milliseconds: 800);

  static const String accessToken = 'accessToken';
  static const String refreshToken = 'refreshToken';

}
