import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/SensorData.dart';

class SensorDataService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  Timer? _locationTimer;

  double accX = 0, accY = 0, accZ = 0;
  double gyroX = 0, gyroY = 0, gyroZ = 0;
  double magX = 0, magY = 0, magZ = 0;
  double latitude = 0, longitude = 0;

  Function(SensorData)? onData;

  Future<void> start() async {

    print('Sensor requestPermission');

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Sensor requestPermission denied');
      return;
    }

    _accelSub = accelerometerEvents.listen((e) {
      accX = e.x;
      accY = e.y;
      accZ = e.z;
    });

    _gyroSub = gyroscopeEvents.listen((e) {
      gyroX = e.x;
      gyroY = e.y;
      gyroZ = e.z;
    });

    _magSub = magnetometerEvents.listen((e) {
      magX = e.x;
      magY = e.y;
      magZ = e.z;
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      latitude = pos.latitude;
      longitude = pos.longitude;

      final data = SensorData(
        timestamp: DateTime.now(),
        accX: accX,
        accY: accY,
        accZ: accZ,
        gyroX: gyroX,
        gyroY: gyroY,
        gyroZ: gyroZ,
        magX: magX,
        magY: magY,
        magZ: magZ,
        latitude: latitude,
        longitude: longitude,
      );

      onData?.call(data);

      debugPrint("Sensor Data: ${data.timestamp}");

      // ✅ Log to console
      print("\n🔽 SENSOR LOG");
      print("🕒 ${data.timestamp}");
      print("📍 GPS: ${data.latitude}, ${data.longitude}");
      print("📈 ACC: X=${data.accX}, Y=${data.accY}, Z=${data.accZ}");
      print("📉 GYRO: X=${data.gyroX}, Y=${data.gyroY}, Z=${data.gyroZ}");
      print("🧲 MAG: X=${data.magX}, Y=${data.magY}, Z=${data.magZ}");

    });
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _locationTimer?.cancel();
  }
}
