import 'package:hive/hive.dart';

part 'sensor_data.g.dart';

@HiveType(typeId: 0)
class SensorData extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final double accX;

  @HiveField(4)
  final double accY;

  @HiveField(5)
  final double accZ;

  @HiveField(6)
  final double gyroX;

  @HiveField(7)
  final double gyroY;

  @HiveField(8)
  final double gyroZ;

  @HiveField(9)
  final double magX;

  @HiveField(10)
  final double magY;

  @HiveField(11)
  final double magZ;

  @HiveField(12)
  final double? pressure;

  @HiveField(13)
  final String sessionId;

  SensorData({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.magX,
    required this.magY,
    required this.magZ,
    required this.sessionId,
    this.pressure,
  });
}
