import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diet_model.dart'; // Import your new models

class DailyIntakeGraph extends StatelessWidget {
  // The graph will take a list of the user's intake records.
  final List<DailyIntakeRecord> intakeRecords;

  const DailyIntakeGraph({super.key, required this.intakeRecords});

  @override
  Widget build(BuildContext context) {
    // Sort records by date and take the last 7 for the graph
    intakeRecords.sort((a, b) => a.date.compareTo(b.date));
    final recentRecords = intakeRecords.length > 7
        ? intakeRecords.sublist(intakeRecords.length - 7)
        : intakeRecords;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xff2c4260),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 3000, // A reasonable max for daily calories
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      // Display the day of the week (e.g., 'Mon', 'Tue')
                      final day = recentRecords[value.toInt()].date;
                        return Text(
    DateFormat.E().format(day),
    style: const TextStyle(color: Colors.white, fontSize: 10),
  );
                    },
                    reservedSize: 38,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value % 1000 == 0 && value > 0) {
                        return Text('${(value / 1000).toInt()}k', style: const TextStyle(color: Colors.white, fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: recentRecords.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: record.calories.toDouble(),
                      color: Colors.lightBlueAccent,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}