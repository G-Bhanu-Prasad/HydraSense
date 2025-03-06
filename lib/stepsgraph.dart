import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StepsActivityChart extends StatefulWidget {
  final List<int> stepsData;
  final String timeFrame; // "daily", "monthly"

  const StepsActivityChart({
    Key? key,
    required this.stepsData,
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
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${widget.stepsData[groupIndex]} steps',
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
                return Text(
                  _getBottomTitle(value.toInt()),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                double highestSteps = _calculateMaxY();
                return value == highestSteps
                    ? Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Text('');
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
        maxY: _calculateMaxY(),
      ),
    );
  }

  /// 📌 **Get x-axis labels for daily or monthly views**
  String _getBottomTitle(int index) {
    if (widget.timeFrame == "daily") {
      switch (index) {
        case 0:
          return '12AM';
        case 4:
          return '4AM';
        case 8:
          return '8AM';
        case 12:
          return '12PM';
        case 16:
          return '4PM';
        case 20:
          return '8PM';
        default:
          return '';
      }
    } else if (widget.timeFrame == "monthly") {
      switch (index) {
        case 0:
          return 'Week 1';
        case 1:
          return 'Week 2';
        case 2:
          return 'Week 3';
        case 3:
          return 'Week 4';
        default:
          return '';
      }
    }
    return '';
  }

  /// 📌 **Calculate maxY dynamically to fit the highest step count**
  double _calculateMaxY() {
    if (widget.stepsData.isEmpty) return 1000; // Default minimum

    double highestSteps =
        widget.stepsData.reduce((a, b) => a > b ? a : b).toDouble();

    return (highestSteps > 0) ? (highestSteps * 1.2).ceilToDouble() : 1000;
  }

  /// 📌 **Build the bar chart groups dynamically**
  List<BarChartGroupData> _buildBarGroups() {
    double maxSteps = widget.stepsData.isNotEmpty
        ? widget.stepsData.reduce((a, b) => a > b ? a : b).toDouble()
        : 1; // Avoid zero-division

    return List.generate(widget.stepsData.length, (index) {
      double scaledValue = (maxSteps > 0)
          ? (widget.stepsData[index] / maxSteps) * _calculateMaxY()
          : 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: scaledValue.isFinite ? scaledValue : 0, // Avoid NaN
            color: _getBarColor(widget.stepsData[index]),
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

  /// 📌 **Color bars based on activity level**
  Color _getBarColor(int steps) {
    if (steps < 500) return Colors.red;
    if (steps < 2000) return Colors.orange;
    if (steps < 5000) return Colors.yellow;
    if (steps < 8000) return Colors.green;
    return Colors.blue;
  }
}
