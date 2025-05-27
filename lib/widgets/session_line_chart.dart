import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SessionLineChart extends StatelessWidget {
  final List<double> values;
  final String title;
  final String unit;

  const SessionLineChart({
    super.key,
    required this.values,
    required this.title,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text('$title: Not enough data to display'),
      );
    }

    final double min = values.reduce((a, b) => a < b ? a : b);
    final double max = values.reduce((a, b) => a > b ? a : b);
    final double avg = values.reduce((a, b) => a + b) / values.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with label and stat summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$title ($unit)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Min: ${min.toStringAsFixed(2)}'),
                    Text('Max: ${max.toStringAsFixed(2)}'),
                    Text('Avg: ${avg.toStringAsFixed(2)}'),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            // Line Chart
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (max - min) / 4,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: AxisTitles(),
                    topTitles: AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      color: Colors.teal,
                      barWidth: 2.5,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
