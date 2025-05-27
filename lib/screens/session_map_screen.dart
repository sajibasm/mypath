import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sensor_data.dart';
import '../models/session_summary.dart';
import '../constants/colors.dart';
import '../widgets/session_line_chart.dart';

class SessionMapScreen extends StatelessWidget {
  const SessionMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionId = ModalRoute.of(context)!.settings.arguments as String;
    final sensorBox = Hive.box<SensorData>('sensor_data');
    final sessionBox = Hive.box<SessionSummary>('session_summary');

    final session = sessionBox.get(sessionId);
    final points = sensorBox.values
        .where((e) => e.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalDistance = 0.0;
    Duration duration = Duration.zero;

    if (points.length >= 2) {
      for (int i = 1; i < points.length; i++) {
        totalDistance += _distanceBetween(points[i - 1], points[i]);
      }
      duration = points.last.timestamp.difference(points.first.timestamp);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
        backgroundColor: AppColors.primary,
      ),
      body: points.length < 2
          ? const Center(child: Text("Not enough points to display charts."))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📍 Points: ${points.length}", style: TextStyle(fontSize: 16)),
                Text("📏 Distance: ${totalDistance.toStringAsFixed(1)} meters", style: TextStyle(fontSize: 16)),
                Text("⏱️ Duration: ${_formatDuration(duration)}", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SessionLineChart(
            values: points.map((e) => e.accZ).toList(),
            title: 'accZ',
            unit: 'm/s²',
          ),
          const SizedBox(height: 24),
          SessionLineChart(
            values: points.map((e) => e.gyroZ).toList(),
            title: 'gyroZ',
            unit: 'rad/s',
          ),
          const SizedBox(height: 24),
          SessionLineChart(
            values: points.map((e) => e.magZ).toList(),
            title: 'magZ',
            unit: 'μT',
          ),
          const SizedBox(height: 24),
          SessionLineChart(
            values: points.map((e) => e.pressure ?? 0.0).toList(),
            title: 'Pressure',
            unit: 'hPa',
          ),
          const SizedBox(height: 24),
          SessionLineChart(
            values: _calculateSpeeds(points),
            title: 'Speed',
            unit: 'm/s',
          ),
        ],
      ),
    );
  }

  List<double> _calculateSpeeds(List<SensorData> points) {
    final speeds = <double>[];
    for (int i = 1; i < points.length; i++) {
      final distance = _distanceBetween(points[i - 1], points[i]);
      final timeDiff = points[i].timestamp.difference(points[i - 1].timestamp).inMilliseconds / 1000.0;
      if (timeDiff > 0) {
        speeds.add(distance / timeDiff); // meters per second
      } else {
        speeds.add(0.0);
      }
    }
    return [0.0, ...speeds]; // pad with zero for first point
  }

  double _distanceBetween(SensorData a, SensorData b) {
    const R = 6371000; // Earth radius in meters
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final aCalc = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(aCalc), sqrt(1 - aCalc));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h}h ${m}m ${s}s';
  }
}
