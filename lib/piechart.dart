import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartSample extends StatelessWidget {
  final int totalGoalsMet;
  final int totalIncompleteGoals;
  final int totalGoalsIncreased;

  const PieChartSample({
    super.key,
    required this.totalGoalsMet,
    required this.totalIncompleteGoals,
    required this.totalGoalsIncreased,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pie Chart
        Center(
          child: Container(
            padding: EdgeInsets.only(left: 30),
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sections: _generateChartSections(),
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
        ),

        const SizedBox(width: 55),
        Container(
          padding: EdgeInsets.only(top: 60),
          child: _buildLegend(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateChartSections() {
    if (totalGoalsMet == 0 &&
        totalIncompleteGoals == 0 &&
        totalGoalsIncreased == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade400,
          title: '',
          radius: 45,
        ),
      ];
    }
    return [
      PieChartSectionData(
        value: totalGoalsMet.toDouble(),
        color: Colors.green,
        title: '$totalGoalsMet',
        radius: 35,
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: totalIncompleteGoals.toDouble(),
        color: Colors.red,
        title: '$totalIncompleteGoals',
        radius: 35,
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: totalGoalsIncreased.toDouble(),
        color: Colors.blue,
        title: '$totalGoalsIncreased',
        radius: 35,
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(Colors.green, "Met"),
        _buildLegendItem(Colors.red, "Incomplete"),
        _buildLegendItem(Colors.blue, "Increased"),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54),
        ),
      ],
    );
  }
}
