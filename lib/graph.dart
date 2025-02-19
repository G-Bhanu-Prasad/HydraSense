import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DailyWaterIntakeChart extends StatelessWidget {
  final List<int> dailyIntakes;

  const DailyWaterIntakeChart({required this.dailyIntakes, super.key});

  Future<void> calculateWeeklyAndMonthlyData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? dailyIntakesJson = prefs.getString('dailyIntakes');
    Map<String, int> dailyIntakes = dailyIntakesJson != null
        ? Map<String, int>.from(jsonDecode(dailyIntakesJson))
        : {};

    List<int> weeklyData = [];
    List<int> monthlyData = [];

    DateTime now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      weeklyData.add(dailyIntakes[dateStr] ?? 0);
    }

    for (int i = 0; i < 30; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      monthlyData.add(dailyIntakes[dateStr] ?? 0);
    }

    weeklyData = weeklyData.reversed.toList();
    monthlyData = monthlyData.reversed.toList();

    print('Weekly Data: $weeklyData');
    print('Monthly Data: $monthlyData');

    prefs.setString('weeklyData', jsonEncode(weeklyData));
    prefs.setString('monthlyData', jsonEncode(monthlyData));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value % 500 == 0) {
                    return Text(
                      '${value.toInt()} ml',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  List<String> dates = List.generate(7, (index) {
                    final date = DateTime.now().subtract(Duration(days: index));
                    return DateFormat('dd\n/MM').format(date);
                  }).reversed.toList();
                  if (value >= 0 && value < dates.length) {
                    return Text(
                      dates[value.toInt()],
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: const Color(0xff37434d),
              width: 1,
            ),
          ),
          barGroups: dailyIntakes.asMap().entries.map((entry) {
            int index = entry.key;
            int value = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value.toDouble(),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.lightBlueAccent],
                  ),
                  width: 28,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          maxY: dailyIntakes.reduce((a, b) => a > b ? a : b).toDouble() + 1000,
        ),
      ),
    );
  }
}
