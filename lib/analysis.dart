import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_2/graph.dart';
import 'package:flutter_application_2/piechart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalysisPage extends StatefulWidget {
  final Map<String, int> dailyIntakes;

  const AnalysisPage({super.key, required this.dailyIntakes});

  @override
  AnalysisPageState createState() => AnalysisPageState();
}

class AnalysisPageState extends State<AnalysisPage> {
  int totalGoalsIncreased = 0; // Retrieve this dynamically
  String selectedView = "Daily"; // Default selection

  @override
  void initState() {
    super.initState();
    _loadTotalGoalsIncreased();
  }

  Future<void> _loadTotalGoalsIncreased() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      totalGoalsIncreased = prefs.getInt('totalGoalsIncreased') ?? 0;
    });
  }

  void _updateSelectedView(String view) {
    setState(() {
      selectedView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic values for the pie chart
    final int totalGoalsMet =
        widget.dailyIntakes.values.where((intake) => intake >= 2000).length;
    final int totalIncompleteGoals =
        widget.dailyIntakes.values.where((intake) => intake < 2000).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row for Daily, Weekly, Monthly selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildViewButton("Daily"),
                  const SizedBox(width: 10),
                  _buildViewButton("Weekly"),
                  //_buildViewButton("Monthly"),
                ],
              ),
              const SizedBox(height: 20),
              // Dynamic content based on selection
              if (selectedView == "Daily")
                _buildDailyView(totalGoalsMet, totalIncompleteGoals),
              if (selectedView == "Weekly")
                _buildWeeklyView(totalGoalsMet, totalIncompleteGoals),
              /*if (selectedView == "Monthly")
                _buildMonthlyView(totalGoalsMet, totalIncompleteGoals),*/
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewButton(String view) {
    return ElevatedButton(
      onPressed: () => _updateSelectedView(view),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedView == view ? Colors.blue : Colors.grey.shade300,
        foregroundColor: selectedView == view ? Colors.white : Colors.black,
      ),
      child: Text(view),
    );
  }

  Widget _buildDailyView(int totalGoalsMet, int totalIncompleteGoals) {
    return Column(
      children: [
        Text(
          'Water Intake (ml):',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        //const SizedBox(height: 15),
        Container(
          height: 200,
          width: 350,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 9, 47, 103),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DailyWaterIntakeChart(
            dailyIntakes: List.generate(7, (index) {
              final date = DateFormat('yyyy-MM-dd')
                  .format(DateTime.now().subtract(Duration(days: index)));
              return widget.dailyIntakes[date] ?? 0;
            }).reversed.toList(),
          ),
        ),
        const SizedBox(height: 15),

        // Pie Chart for Goals
        Text(
          'Goal Consistency:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          width: 300,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: PieChartSample(
            totalGoalsMet: totalGoalsMet,
            totalIncompleteGoals: totalIncompleteGoals,
            totalGoalsIncreased: totalGoalsIncreased,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyView(int totalGoalsMet, int totalIncompleteGoals) {
    return Column(
      children: [
        Text(
          'Weekly data ikkada ravali',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        /*const SizedBox(height: 15),
        Container(
          height: 200,
          width: 350,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 9, 47, 103),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DailyWaterIntakeChart(
            dailyIntakes: List.generate(7, (index) {
              final date = DateFormat('yyyy-MM-dd')
                  .format(DateTime.now().subtract(Duration(days: index)));
              return widget.dailyIntakes[date] ?? 0;
            }).reversed.toList(),
          ),
        ),
        const SizedBox(height: 15),
        // Pie Chart for Goals
        Text(
          'Goal Consistency:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          width: 300,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: PieChartSample(
            totalGoalsMet: totalGoalsMet,
            totalIncompleteGoals: totalIncompleteGoals,
            totalGoalsIncreased: totalGoalsIncreased,
          ),
        ),*/
      ],
    );
  }

  /*Widget _buildMonthlyView(int totalGoalsMet, int totalIncompleteGoals) {
    return Column(
      children: [
        Text(
          'Water Intake (ml):',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Container(
          height: 200,
          width: 350,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 9, 47, 103),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DailyWaterIntakeChart(
            dailyIntakes: List.generate(7, (index) {
              final date = DateFormat('yyyy-MM-dd')
                  .format(DateTime.now().subtract(Duration(days: index)));
              return widget.dailyIntakes[date] ?? 0;
            }).reversed.toList(),
          ),
        ),
        const SizedBox(height: 15),
        // Pie Chart for Goals
        Text(
          'Goal Consistency:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          width: 300,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: PieChartSample(
            totalGoalsMet: totalGoalsMet,
            totalIncompleteGoals: totalIncompleteGoals,
            totalGoalsIncreased: totalGoalsIncreased,
          ),
        ),
      ],
    );
  }*/
}
