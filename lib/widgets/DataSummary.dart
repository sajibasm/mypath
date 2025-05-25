import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart';

class DataSummaryWidget extends StatelessWidget {
  const DataSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final data = <String, double>{
      "Jan": 1.4,
      "Feb": 2.1,
      "Mar": 3.0,
      "Apr": 2.5,
      "May": 3.5,
      "Jun": 4.0,
    };

    return Container(
      color: AppColors.white, // ✅ Use your constant
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mapPadding),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.mapPadding),
            child: Column(
              children: [
                const Text(
                  "Contribution Summary",
                  style: AppTextStyles.subtitle, // ✅ Use your subtitle style
                ),
                const SizedBox(height: 20),
                SizedBox(height: 250, child: _buildLineChart(data)),
                const SizedBox(height: 16),
                Text(
                  "Total Sessions: ${data.length}",
                  style: AppTextStyles.label, // ✅ Consistent label style
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LineChart _buildLineChart(Map<String, double> data) {
    final entries = data.entries.toList();

    return LineChart(
      LineChartData(
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              entries.length,
                  (index) => FlSpot(index.toDouble(), entries[index].value),
            ),
            isCurved: true,
            dotData: FlDotData(show: true),
            color: AppColors.primary, // ✅ Use your primary color
            barWidth: 3,
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              interval: 1,
              showTitles: true,
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index < entries.length) {
                  return Text(
                    entries[index].key,
                    style: AppTextStyles.formHint, // ✅ Clean title font for axis
                  );
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: AppTextStyles.formHint,
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
      ),
    );
  }
}
