import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:MyPath/constants/colors.dart';

import '../models/session_summary.dart';
import '../models/sensor_data.dart';
import '../services/UploaderService.dart';
import '../constants/secrets.dart';

const MAPS_API_KEY = Secrets.GoogleMapsAPI; // 🔁 Replace this

class DataLogScreen extends StatefulWidget {
  const DataLogScreen({super.key});

  @override
  State<DataLogScreen> createState() => _DataLogScreenState();
}

class _DataLogScreenState extends State<DataLogScreen> {
  late Box<SessionSummary> sessionBox;
  late Box<SensorData> sensorBox;

  @override
  void initState() {
    super.initState();
    sessionBox = Hive.box<SessionSummary>('session_summary');
    sensorBox = Hive.box<SensorData>('sensor_data');
  }

  Future<void> _uploadSession(String sessionId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Uploading data..."),
        duration: Duration(seconds: 2),
      ),
    );

    await UploaderService.uploadSession(sessionId);
    setState(() {}); // Refresh UI
  }

  String _buildStaticMapUrl(List<LatLng> points) {
    final path = points.map((p) => '${p.latitude},${p.longitude}').join('|');
    final start = points.first;
    final end = points.last;
    return Uri.parse(
      'https://maps.googleapis.com/maps/api/staticmap'
          '?size=600x300'
          '&scale=2'
          '&maptype=roadmap'
          '&markers=color:green%7Clabel:S%7C${start.latitude},${start.longitude}'
          '&markers=color:red%7Clabel:E%7C${end.latitude},${end.longitude}'
          '&path=color:0x0000ff|weight:4|$path'
          '&key=$MAPS_API_KEY',
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = sessionBox.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Log'),
        backgroundColor: AppColors.primary,
      ),
      body: sessions.isEmpty
          ? const Center(child: Text("No sessions recorded yet."))
          : ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final points = sensorBox.values
              .where((e) => e.sessionId == session.id)
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          final routePoints = points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  title: Text("Session: ${session.id.substring(0, 19)}"),
                  subtitle: Text(
                    "Start Time: ${session.startTime}\nPoints Collected: ${session.pointCount}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/session-details',
                      arguments: session.id,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        session.isPendingUpload
                            ? (session.isPartialUpload
                            ? '⏳ Partially Uploaded'
                            : '📤 Not Uploaded')
                            : '✅ Fully Uploaded',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: session.isPendingUpload
                              ? (session.isPartialUpload
                              ? Colors.orange
                              : Colors.red)
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (routePoints.length >= 2)
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/session-map',
                        arguments: session.id,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _buildStaticMapUrl(routePoints),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            height: 150,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 150,
                          child: Center(
                              child: Text("Map image failed to load")),
                        ),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("Not enough data to show route"),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(
                      session.isPendingUpload
                          ? (session.isPartialUpload
                          ? 'Resume Upload ⏳'
                          : 'Upload Data')
                          : 'Uploaded ✔',
                    ),
                    onPressed: session.isPendingUpload
                        ? () => _uploadSession(session.id)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: session.isPendingUpload
                          ? AppColors.primary
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
