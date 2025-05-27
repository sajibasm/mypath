import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class SensorOverlayPanel extends StatefulWidget {
  final SensorData sensorData;
  final double totalDistance;
  final double speed;
  final DateTime? startTime;
  final String Function(Duration) formatDuration;

  const SensorOverlayPanel({
    super.key,
    required this.sensorData,
    required this.totalDistance,
    required this.speed,
    required this.startTime,
    required this.formatDuration,
  });

  @override
  State<SensorOverlayPanel> createState() => _SensorOverlayPanelState();
}

class _SensorOverlayPanelState extends State<SensorOverlayPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📍 Live Tracking Data",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _dataRow("🕒 Time", widget.sensorData.timestamp.toIso8601String()),
          _dataRow("📌 GPS", "Lat: ${widget.sensorData.latitude.toStringAsFixed(5)}, Lng: ${widget.sensorData.longitude.toStringAsFixed(5)}"),
          _dataRow("💨 Speed", "${widget.speed.toStringAsFixed(2)} m/s"),
          if (_expanded) ...[
            _dataRow("📏 Distance", "${(widget.totalDistance / 1000).toStringAsFixed(2)} km"),
            _dataRow("⏱️ Duration", widget.startTime != null
                ? widget.formatDuration(DateTime.now().difference(widget.startTime!))
                : "--:--"),
            const Divider(height: 24),
            const Text(
              "📈 Motion Sensors",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (widget.sensorData.pressure != null)
              _dataRow("🌡️ Pressure", "${widget.sensorData.pressure!.toStringAsFixed(2)} hPa"),
            _dataRow("🎯 Accelerometer",
                "X=${widget.sensorData.accX.toStringAsFixed(2)}, Y=${widget.sensorData.accY.toStringAsFixed(2)}, Z=${widget.sensorData.accZ.toStringAsFixed(2)}"),
            _dataRow("🎯 Gyroscope",
                "X=${widget.sensorData.gyroX.toStringAsFixed(2)}, Y=${widget.sensorData.gyroY.toStringAsFixed(2)}, Z=${widget.sensorData.gyroZ.toStringAsFixed(2)}"),
            _dataRow("🎯 Magnetometer",
                "X=${widget.sensorData.magX.toStringAsFixed(2)}, Y=${widget.sensorData.magY.toStringAsFixed(2)}, Z=${widget.sensorData.magZ.toStringAsFixed(2)}"),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(_expanded ? 'Collapse' : 'Expand'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
