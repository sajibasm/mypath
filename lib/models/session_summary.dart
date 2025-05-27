import 'package:hive/hive.dart';
part 'session_summary.g.dart';

@HiveType(typeId: 1)
class SessionSummary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final int pointCount;

  @HiveField(3)
  String? serverSessionId;

  @HiveField(4)
  bool isPendingUpload;

  @HiveField(5)
  bool isPartialUpload;

  @HiveField(6)
  int wheelchairId; // ✅ new field (non-null)

  SessionSummary({
    required this.id,
    required this.startTime,
    required this.pointCount,
    required this.wheelchairId, // ✅ required now
    this.serverSessionId,
    this.isPendingUpload = true,
    this.isPartialUpload = false,
  });
}
