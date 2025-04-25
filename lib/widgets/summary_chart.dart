import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SummaryChart extends StatelessWidget {
  const SummaryChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 60,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) => Text('${value.toInt()}k', style: const TextStyle(color: Colors.white70)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                const months = ['MAR', 'JUN', 'SEP'];
                if (value == 2) return const Text('MAR', style: TextStyle(color: Colors.white70));
                if (value == 5) return const Text('JUN', style: TextStyle(color: Colors.white70));
                if (value == 8) return const Text('SEP', style: TextStyle(color: Colors.white70));
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 10),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: Colors.white,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.blueAccent.withOpacity(0.4), Colors.teal.withOpacity(0.3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            gradient: const LinearGradient(
              colors: [Colors.lightBlueAccent, Colors.greenAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            spots: const [
              FlSpot(0, 30),
              FlSpot(1, 20),
              FlSpot(2, 10),
              FlSpot(3, 40),
              FlSpot(4, 30),
              FlSpot(5, 50),
              FlSpot(6, 30),
              FlSpot(7, 25),
              FlSpot(8, 35),
            ],
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black54,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((spot) => LineTooltipItem(
              '${spot.y.toStringAsFixed(0)}k',
              const TextStyle(color: Colors.white),
            ))
                .toList(),
          ),
          handleBuiltInTouches: true,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white30, width: 1),
        ),
      ),
    );
  }
}
