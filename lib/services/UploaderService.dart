import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/sensor_data.dart';
import '../models/session_summary.dart';
import 'APIService.dart';
import 'StorageService.dart';

class UploaderService {
  static Future<void> uploadSession(String localSessionId) async {

    final wifiOnly = await StorageService.getWiFiOnlyUploadSetting();
    final connection = await Connectivity().checkConnectivity();

    print("WiFi Only? $wifiOnly, Connection: $connection");

// Check if list contains wifi
    final isWifi = connection is ConnectivityResult
        ? connection == ConnectivityResult.wifi
        : (connection is List && connection.contains(ConnectivityResult.wifi));

    if (wifiOnly && !isWifi) {
      print("⚠️ Upload skipped: Not connected to Wi-Fi");
      return;
    }

    final sensorBox = Hive.box<SensorData>('sensor_data');
    final sessionBox = Hive.box<SessionSummary>('session_summary');

    final session = sessionBox.get(localSessionId);
    if (session == null) {
      print("❌ Session not found in local DB");
      return;
    }

    final data = sensorBox.values
        .where((e) => e.sessionId == localSessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (data.isEmpty) {
      print("⚠️ No sensor data found for session: $localSessionId");
      return;
    }

    // ✅ Create server session if not yet created
    if (session.serverSessionId == null) {
      final serverSessionId = await APIService.createSensorSession(
        wheelchairId: session.wheelchairId,
        start: data.first.timestamp,
        end: data.last.timestamp,
      );

      if (serverSessionId == null) {
        print("❌ Could not create session on server. Will retry later.");
        session.isPendingUpload = true;
        await session.save();
        return;
      }

      session.serverSessionId = serverSessionId;
      await session.save();
      print("✅ Server session created and saved: $serverSessionId");
    }

    // ✅ Upload in chunks
    const chunkSize = 50;
    for (int i = 0; i < data.length; i += chunkSize) {
      final chunk = data.sublist(i, (i + chunkSize > data.length) ? data.length : i + chunkSize);

      final success = await APIService.uploadSensorData(
        sensorSessionId: session.serverSessionId!,
        chunk: chunk,
      );

      if (success) {
        print("✅ Uploaded chunk ${i ~/ chunkSize + 1}");
      } else {
        print("❌ Upload failed for chunk ${i ~/ chunkSize + 1}");
        session.isPartialUpload = true;
        await session.save();
        return;
      }
    }

    // ✅ Mark session as fully uploaded
    session.isPendingUpload = false;
    session.isPartialUpload = false;
    await session.save();

    print("✅ All data uploaded successfully for session: $localSessionId");
  }
}
