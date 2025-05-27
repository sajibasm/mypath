import 'package:MyPath/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/sensor_data.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionId = ModalRoute.of(context)!.settings.arguments as String;
    final sensorBox = Hive.box<SensorData>('sensor_data');

    // Filter and sort data by timestamp
    final sessionPoints = sensorBox.values
        .where((e) => e.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: AppColors.primary,
      ),
      body: sessionPoints.isEmpty
          ? const Center(child: Text('No data points found for this session.'))
          : ListView.builder(
        itemCount: sessionPoints.length,
        itemBuilder: (context, index) {
          final data = sessionPoints[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.teal),
              title: Text(
                "Location: (${data.latitude.toStringAsFixed(6)}, ${data.longitude.toStringAsFixed(6)})",
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Time: ${data.timestamp.toLocal()}"),
                  const SizedBox(height: 4),
                  Text("Accelerometer: X=${data.accX.toStringAsFixed(2)}, Y=${data.accY.toStringAsFixed(2)}, Z=${data.accZ.toStringAsFixed(2)}"),
                  Text("Gyroscope:     X=${data.gyroX.toStringAsFixed(2)}, Y=${data.gyroY.toStringAsFixed(2)}, Z=${data.gyroZ.toStringAsFixed(2)}"),
                  Text("Magnetometer:  X=${data.magX.toStringAsFixed(2)}, Y=${data.magY.toStringAsFixed(2)}, Z=${data.magZ.toStringAsFixed(2)}"),
                  if (data.pressure != null)
                    Text("Pressure:      ${data.pressure!.toStringAsFixed(2)} hPa"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
