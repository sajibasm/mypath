import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart';
import '../services/APIService.dart';

class DataSummaryWidget extends StatefulWidget {
  const DataSummaryWidget({super.key});

  @override
  State<DataSummaryWidget> createState() => _DataSummaryWidgetState();
}

class _DataSummaryWidgetState extends State<DataSummaryWidget> {
  bool _showMonthly = true;
  bool _loading = true;
  String? _error;

  Map<String, double> _dailyData = {};
  Map<String, double> _monthlyData = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final daily = await APIService.getDailySessionSummary();
      final monthly = await APIService.getMonthlySessionSummary();

      if (daily == null || monthly == null) {
        throw Exception("Failed to load data");
      }

      setState(() {
        _dailyData = daily;
        _monthlyData = monthly;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Failed to load session data.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _showMonthly ? _monthlyData : _dailyData;

    return Container(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mapPadding),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.mapPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Contribution Summary",
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Daily", style: AppTextStyles.formHint),
                    Switch(
                      value: _showMonthly,
                      activeColor: AppColors.primary,
                      onChanged: (value) => setState(() => _showMonthly = value),
                    ),
                    const Text("Monthly", style: AppTextStyles.formHint),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 16, height: 4, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text("Session Count", style: AppTextStyles.formHint),
                  ],
                ),
                const SizedBox(height: 16),
                _loading
                    ? const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                )
                    : _error != null
                    ? SizedBox(
                  height: 250,
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                    : _buildChart(currentData),
                const SizedBox(height: 16),
                Text(
                  "Total Sessions: ${currentData.values.fold<double>(0, (sum, v) => sum + v).toStringAsFixed(1)}",
                  style: AppTextStyles.label,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LineChart _buildLineChart(List<MapEntry<String, double>> entries) {
    final values = entries.map((e) => e.value).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: values.asMap().entries.map(
                  (e) => FlSpot(e.key.toDouble(), e.value),
            ).toList(),
            color: Colors.teal,
            barWidth: 2.5,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.teal.withOpacity(0.2),
            ),
          ),
        ],
        titlesData: _buildTitlesData(entries),
        gridData: FlGridData(show: true),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final label = entries[spot.spotIndex].key;
                final value = entries[spot.spotIndex].value.toStringAsFixed(1);
                return LineTooltipItem(
                  '$label\n$value sessions',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }


  FlTitlesData _buildTitlesData(List<MapEntry<String, double>> entries) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, _) {
            final index = value.toInt();
            if (index >= 0 && index < entries.length) {
              // ✅ Show all months for monthly view
              if (_showMonthly ||
                  index == 0 ||
                  index == entries.length ~/ 2 ||
                  index == entries.length - 1) {
                return Transform.rotate(
                  angle: -0.4,
                  child: Text(
                    entries[index].key,
                    style: AppTextStyles.formHint.copyWith(fontSize: 10),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },

        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }


  BarChart _buildBarChart(List<MapEntry<String, double>> entries) {
    return BarChart(
      BarChartData(
        barGroups: List.generate(entries.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entries[index].value,
                color: Colors.teal,
                width: 20,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: entries.map((e) => e.value).reduce((a, b) => a > b ? a : b),
                  color: Colors.grey.shade200,
                ),
              ),
            ],
          );
        }),
        titlesData: _buildTitlesData(entries),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${entries[group.x].key}\n${rod.toY.toStringAsFixed(1)} sessions',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }



  Widget _buildChart(Map<String, double> data) {
    final entries = data.entries.toList();

    return SizedBox(
      height: 250,
      width: MediaQuery.of(context).size.width, // Fit screen
      child: _showMonthly
          ? _buildBarChart(entries)
          : _buildLineChart(entries),
    );
  }

}
