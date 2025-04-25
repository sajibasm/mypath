import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationUtils {
  static final Location _location = Location();

  /// Check and request permission, return LatLng if granted
  static Future<LatLng?> checkAndRequestLocationPermission() async {
    final hasPermission = await _location.hasPermission();

    if (hasPermission == PermissionStatus.granted) {
      final loc = await _location.getLocation();
      return LatLng(loc.latitude!, loc.longitude!);
    }

    final requested = await _location.requestPermission();
    if (requested == PermissionStatus.granted) {
      final loc = await _location.getLocation();
      return LatLng(loc.latitude!, loc.longitude!);
    }

    return null;
  }

  /// Just check if permission is granted (no request)
  static Future<bool> isPermissionGranted() async {
    final status = await _location.hasPermission();
    return status == PermissionStatus.granted;
  }
}
