import 'package:location/location.dart';
import 'BaseServices.dart';

class RealLocationService implements LocationServiceBase {
  final Location _location = Location();

  @override
  Stream<LocationData> get locationStream => _location.onLocationChanged;

  @override
  Future<LocationData> getCurrentLocation() => _location.getLocation();

  @override
  void stop() {
    // No stream to manually cancel, since Geolocator manages it
    print("🛑 RealLocationService: stop() called — no-op");
  }

}
