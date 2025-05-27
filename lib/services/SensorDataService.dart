import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import '../models/sensor_data.dart';
import '../models/session_summary.dart';

class SensorDataService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<BarometerEvent>? _pressureSub;

  late Box<SensorData> _sensorBox;
  late Box<SessionSummary> _summaryBox;

  String? _currentSessionId;
  Timer? _recordingTimer;

  double accX = 0, accY = 0, accZ = 0;
  double gyroX = 0, gyroY = 0, gyroZ = 0;
  double magX = 0, magY = 0, magZ = 0;
  double latitude = 0, longitude = 0;
  double? _pressure;

  Function(SensorData)? onData;
  int? _wheelchairId;

  Future<void> start({required int wheelchairId}) async {
    print('✅ Sensor collection starting...');
    _wheelchairId = wheelchairId;

    _sensorBox = await Hive.openBox<SensorData>('sensor_data');
    _summaryBox = await Hive.openBox<SessionSummary>('session_summary');

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('❌ Location permission denied');
      return;
    }

    _currentSessionId = DateTime.now().toIso8601String();

    // Subscribe to sensor streams
    _accelSub = accelerometerEventStream().listen((e) {
      accX = e.x;
      accY = e.y;
      accZ = e.z;
    });

    _gyroSub = gyroscopeEventStream().listen((e) {
      gyroX = e.x;
      gyroY = e.y;
      gyroZ = e.z;
    });

    _magSub = magnetometerEventStream().listen((e) {
      magX = e.x;
      magY = e.y;
      magZ = e.z;
    });

    _pressureSub = barometerEventStream().listen((e) {
      _pressure = e.pressure;
    });


    // Collect sensor + GPS every 20ms (~50Hz)
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 5),
        );


        latitude = pos.latitude;
        longitude = pos.longitude;

        final accMagnitude = sqrt(accX * accX + accY * accY + accZ * accZ);
        final gyroMagnitude = sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);
        final magMagnitude = sqrt(magX * magX + magY * magY + magZ * magZ);


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
          pressure: _pressure,
          sessionId: _currentSessionId!,
        );

        await _sensorBox.add(data);
        onData?.call(data);

        // Log for debug
        print("🕒 ${data.timestamp}");
        print("📍 GPS: ${data.latitude}, ${data.longitude}");
        print("📈 ACC Mag: ${accMagnitude.toStringAsFixed(2)}");
        print("📉 GYRO Mag: ${gyroMagnitude.toStringAsFixed(2)}");
        print("🧲 MAG Mag: ${magMagnitude.toStringAsFixed(2)}");

      } catch (e) {
        print("⚠️ GPS fetch failed: $e");
        // Optionally keep last known GPS or mark as invalid
      }
    });
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _pressureSub?.cancel();
    _recordingTimer?.cancel();

    if (_currentSessionId != null && _wheelchairId != null) {
      final points = _sensorBox.values
          .where((e) => e.sessionId == _currentSessionId)
          .toList();

      if (points.isNotEmpty) {
        final summary = SessionSummary(
          id: _currentSessionId!,
          startTime: points.first.timestamp,
          pointCount: points.length,
          wheelchairId: _wheelchairId!,
        );
        _summaryBox.put(summary.id, summary);
        print("📝 Session summary saved locally with wheelchair ID: $_wheelchairId");
      }

      _currentSessionId = null;
      _wheelchairId = null;
    }
  }
}
