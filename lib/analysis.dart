import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_2/graph.dart';
import 'package:flutter_application_2/piechart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navbar.dart';
import 'home_screen.dart';

class AnalysisPage extends StatefulWidget {
  final Map<String, int> dailyIntakes;

  const AnalysisPage({super.key, required this.dailyIntakes});

  @override
  AnalysisPageState createState() => AnalysisPageState();
}

class AnalysisPageState extends State<AnalysisPage> {
  int totalGoalsIncreased = 0;
  String selectedView = "Daily";
  final PageController _pageController = PageController();

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
      _pageController.animateToPage(
        view == "Daily" ? 0 : 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final int totalGoalsMet =
        widget.dailyIntakes.values.where((intake) => intake >= 2000).length;
    final int totalIncompleteGoals =
        widget.dailyIntakes.values.where((intake) => intake < 2000).length;

    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileDisplayScreen()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Analysis',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Toggle buttons for Daily & Weekly
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildViewButton("Daily"),
                const SizedBox(width: 10),
                _buildViewButton("Weekly"),
              ],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    selectedView = index == 0 ? "Daily" : "Weekly";
                  });
                },
                children: [
                  _buildDailyView(totalGoalsMet, totalIncompleteGoals),
                  _buildWeeklyView(totalGoalsMet, totalIncompleteGoals),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 3),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Water Intake (ml):',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
      ),
    );
  }

  Widget _buildWeeklyView(int totalGoalsMet, int totalIncompleteGoals) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Weekly Analysis Data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            height: 200,
            width: 350,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 9, 47, 103),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "Weekly Data Goes Here",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 15),
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
      ),
    );
  }
}
