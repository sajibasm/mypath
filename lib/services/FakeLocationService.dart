import 'dart:async';

import 'package:location/location.dart';

import 'BaseServices.dart';

class FakeLocationService implements LocationServiceBase {
  final StreamController<LocationData> _controller =
  StreamController<LocationData>.broadcast();

  double _lat = 39.281260;
  double _lng = -76.757267;
  Timer? _timer;

  FakeLocationService(); // Don't auto-start

  void _simulateFakeStream() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _lat += 0.00005;
      _lng += 0.00005;

      final fakeData = LocationData.fromMap({
        "latitude": _lat,
        "longitude": _lng,
        "accuracy": 5.0,
        "altitude": 0.0,
        "speed": 1.5,
        "speed_accuracy": 0.5,
        "heading": 0.0,
        "time": DateTime.now().millisecondsSinceEpoch.toDouble(),
        "isMock": true,
        "verticalAccuracy": 1.0,
        "bearingAccuracy": 1.0,
        "elapsedRealtimeNanos": 0.0,
        "elapsedRealtimeUncertaintyNanos": 0.0,
        "satelliteNumber": 0,
        "provider": "mock",
        "floor": 0,
        "isFromMockProvider": true,
      });

      print("📍 EMITTING FAKE LOCATION: $_lat, $_lng");
      _controller.add(fakeData);
    });
  }

  void start() {
    if (_timer == null || !_timer!.isActive) {
      print("▶️ Fake location stream restarted.");
      _simulateFakeStream();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    print("🛑 Fake location stream stopped.");
  }

  @override
  Stream<LocationData> get locationStream => _controller.stream;

  @override
  Future<LocationData> getCurrentLocation() async {
    final fakeData = LocationData.fromMap({
      "latitude": _lat,
      "longitude": _lng,
      "accuracy": 5.0,
      "altitude": 0.0,
      "speed": 1.5,
      "speed_accuracy": 0.5,
      "heading": 0.0,
      "time": DateTime.now().millisecondsSinceEpoch.toDouble(),
      "isMock": true,
      "verticalAccuracy": 1.0,
      "bearingAccuracy": 1.0,
      "elapsedRealtimeNanos": 0.0,
      "elapsedRealtimeUncertaintyNanos": 0.0,
      "satelliteNumber": 0,
      "provider": "mock",
      "floor": 0,
      "isFromMockProvider": true,
    });

    print("📍 RETURNING INITIAL FAKE LOCATION: $_lat, $_lng");
    return fakeData;
  }
}
