import 'dart:async';
import '../models/sensor_data.dart';
import 'SensorDataService.dart';

class FakeSensorDataService extends SensorDataService {
  Timer? _timer;
  int _counter = 0;

  @override
  Future<void> start({required int wheelchairId}) async {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final fakePressure = 1013.25 + (_counter % 10) * 0.1;

      final data = SensorData(
        timestamp: DateTime.now(),
        accX: 0.1 * timer.tick,
        accY: 0.2 * timer.tick,
        accZ: 0.3 * timer.tick,
        gyroX: 0.1 * timer.tick,
        gyroY: 0.2 * timer.tick,
        gyroZ: 0.3 * timer.tick,
        magX: 0.01 * timer.tick,
        magY: 0.02 * timer.tick,
        magZ: 0.03 * timer.tick,
        latitude: 39.281260 + _counter * 0.00005,
        longitude: -76.757267 + _counter * 0.00005,
        pressure: fakePressure,
        sessionId: DateTime.now().toIso8601String(),
      );

      onData?.call(data);
      _counter++;
    });
  }


  @override
  void stop() {
    _timer?.cancel();
  }
}
