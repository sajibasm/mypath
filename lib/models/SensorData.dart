class SensorData {
  final DateTime timestamp;
  final double accX, accY, accZ;
  final double gyroX, gyroY, gyroZ;
  final double magX, magY, magZ;
  final double latitude, longitude;

  SensorData({
    required this.timestamp,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.magX,
    required this.magY,
    required this.magZ,
    required this.latitude,
    required this.longitude,
  });
}
