import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StepsActivityChart extends StatefulWidget {
  final List<int> dailySteps;
  final String timeFrame; // "daily", "weekly", "monthly"

  const StepsActivityChart({
    Key? key,
    required this.dailySteps,
    this.timeFrame = "daily",
  }) : super(key: key);

  @override
  State<StepsActivityChart> createState() => _StepsActivityChartState();
}

class _StepsActivityChartState extends State<StepsActivityChart> {
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            //tooltipBackgroundColor: Colors.black.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${widget.dailySteps[groupIndex]} steps',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                switch (widget.timeFrame) {
                  case "daily":
                    switch (value.toInt()) {
                      case 0:
                        text = '12AM';
                        break;
                      case 4:
                        text = '4AM';
                        break;
                      case 8:
                        text = '8AM';
                        break;
                      case 12:
                        text = '12PM';
                        break;
                      case 16:
                        text = '4PM';
                        break;
                      case 20:
                        text = '8PM';
                        break;
                      default:
                        text = '';
                    }
                    break;
                  case "weekly":
                    switch (value.toInt()) {
                      case 0:
                        text = 'Mon';
                        break;
                      case 1:
                        text = 'Tue';
                        break;
                      case 2:
                        text = 'Wed';
                        break;
                      case 3:
                        text = 'Thu';
                        break;
                      case 4:
                        text = 'Fri';
                        break;
                      case 5:
                        text = 'Sat';
                        break;
                      case 6:
                        text = 'Sun';
                        break;
                      default:
                        text = '';
                    }
                    break;
                  case "monthly":
                    if (value.toInt() % 5 == 0) {
                      text = '${value.toInt() + 1}';
                    }
                    break;
                }
                return Text(
                  text,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Only show some values for cleaner appearance
                double highestSteps = _calculateMaxY();

                // Only show the highest step count as a label
                if (value == highestSteps) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: _buildBarGroups(),
        maxY: _calculateMaxY(),
      ),
    );
  }

  // Dynamic calculation of maxY based on step data
  double _calculateMaxY() {
    if (widget.dailySteps.isEmpty) return 0; // Default minimum value

    double highestSteps =
        widget.dailySteps.reduce((a, b) => a > b ? a : b).toDouble();

    return (highestSteps <= 0)
        ? 0
        : highestSteps; // Show only the highest steps
  }

  List<BarChartGroupData> _buildBarGroups() {
    double maxSteps = widget.dailySteps.isNotEmpty
        ? widget.dailySteps.reduce((a, b) => a > b ? a : b).toDouble()
        : 1000;

    return List.generate(widget.dailySteps.length, (index) {
      double scaledValue =
          (widget.dailySteps[index] / maxSteps) * _calculateMaxY();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: scaledValue, // Adjusted value to ensure correct height
            color: _getBarColor(widget.dailySteps[index]),
            width: widget.timeFrame == "daily" ? 8 : 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  // Color bars based on activity level
  Color _getBarColor(int steps) {
    if (steps < 500) return Colors.red;
    if (steps < 2000) return Colors.orange;
    if (steps < 5000) return Colors.yellow;
    if (steps < 8000) return Colors.green;
    return Colors.blue;
  }
}
