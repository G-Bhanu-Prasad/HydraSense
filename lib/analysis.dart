import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_2/graph.dart';
import 'package:flutter_application_2/piechart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navbar.dart';
import 'home_screen.dart';
import 'stepsgraph.dart';

class AnalysisPage extends StatefulWidget {
  final Map<String, int> dailyIntakes;

  const AnalysisPage({super.key, required this.dailyIntakes});

  @override
  AnalysisPageState createState() => AnalysisPageState();
}

class AnalysisPageState extends State<AnalysisPage> {
  int totalGoalsIncreased = 0;
  String selectedView = "D";
  final PageController _pageController = PageController();
  DateTime selectedDate = DateTime.now();
  List<int> hourlySteps = List.generate(24, (index) => 0);
  List<int> dailySteps = List.generate(7, (index) => 0);
  List<int> monthlySteps = List.generate(4, (index) => 0);

  @override
  void initState() {
    super.initState();
    _loadTotalGoalsIncreased();
    _loadStepsData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _loadStepsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();

    List<int> hourly = List.generate(24, (index) {
      String key = "steps_${now.year}_${now.month}_${now.day}_$index";
      return prefs.getInt(key) ?? 0;
    });

    List<int> weekly = [];
    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String key = "steps_${date.year}_${date.month}_${date.day}";
      weekly.add(prefs.getInt(key) ?? 0);
    }

    List<int> monthly = List.generate(4, (week) {
      String key = "steps_${now.year}_${now.month}_week${week + 1}";
      return prefs.getInt(key) ?? 0;
    });

    setState(() {
      hourlySteps = hourly;
      dailySteps = weekly.reversed.toList();
      monthlySteps = monthly;
    });
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
        view == "D" ? 0 : 1,
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Analysis',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                height: 48,
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.cyan.shade900, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSegmentButton('D', 'Daily'),
                    _buildSegmentButton('M', 'Monthly'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      selectedView = index == 0 ? "D" : "M";
                    });
                  },
                  children: [
                    _buildDailyView(totalGoalsMet, totalIncompleteGoals),
                    _buildMonthlyView(totalGoalsMet, totalIncompleteGoals),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildSegmentButton(String value, String label) {
    bool isSelected = value == selectedView;
    return GestureDetector(
      onTap: () => _updateSelectedView(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.shade900 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.cyan.shade900.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGraphContainer({
    required String title,
    required String value,
    required Color valueColor,
    required Widget chart,
  }) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.2),
            Colors.lightBlue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey, fontSize: 14)),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildDailyView(int totalGoalsMet, int totalIncompleteGoals) {
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayIntake = widget.dailyIntakes[todayDate] ?? 0;

    final averageHourlyIntake = (todayIntake / 24).toStringAsFixed(1);
    //final averageHourlySteps = (widget.hourlySteps.reduce((a, b) => a + b) / 24).toStringAsFixed(1);
    // Calculate average

    return SingleChildScrollView(
      child: Column(
        children: [
          //SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Row(
                    children: [
                      // Text(
                      //   "Today ",
                      //   style: TextStyle(
                      //     fontSize: 20,
                      //     fontWeight: FontWeight.w500,
                      //     color: Colors.cyan.shade500,
                      //   ),
                      // ),
                      Text(
                        DateFormat('EEEE dd').format(selectedDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.cyan.shade500,
                        ),
                      ),
                      // SizedBox(width: 8),
                      // Icon(
                      //   Icons.touch_app,
                      //   size: 20,
                      //   color: Colors.cyan.shade500,
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          _buildGraphContainer(
            title: 'HOURLY AVERAGE WATER INTAKE',
            value: '$averageHourlyIntake ml', // Show average
            valueColor: Colors.blue,
            chart: const HourlyWaterIntakeChart(), // Hourly chart widget
          ),
          // SizedBox(height: 10),
          // _buildGraphContainer(
          //   title: 'HOURLY Steps',
          //   value: '', // Show average
          //   valueColor: Colors.pink,
          //   chart: const HourlyStepsChart(), // Hourly chart widget
          // ),
          SizedBox(height: 10),
          _buildGraphContainer(
            title: 'HOURLY STEPS',
            value:
                '${(hourlySteps.reduce((a, b) => a + b) / hourlySteps.length).round()} steps/hr',
            valueColor: Colors.pink,
            chart: StepsActivityChart(
              stepsData: hourlySteps,
              timeFrame: "daily",
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 170,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade900, width: 1),
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

  Widget _buildMonthlyView(int totalGoalsMet, int totalIncompleteGoals) {
    // Similar structure to daily view but with weekly data
    final averageIntake = widget.dailyIntakes.values.isEmpty
        ? 0
        : widget.dailyIntakes.values.reduce((a, b) => a + b) / 7;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(selectedDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.cyan.shade500,
                        ),
                      ),
                      //SizedBox(width: 8),
                      // Icon(
                      //   Icons.touch_app,
                      //   size: 20,
                      //   color: Colors.cyan.shade500,
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          _buildGraphContainer(
            title: 'MONTHLY AVERAGE WATER INTAKE',
            value:
                '${(widget.dailyIntakes.values.isNotEmpty ? widget.dailyIntakes.values.reduce((a, b) => a + b) / 4 : 0).round()} ml',
            valueColor: Colors.blue,
            chart: MonthlyWaterIntakeChart(
              weeklyAverages: List.generate(4, (index) {
                int sum = 0, count = 0;
                for (int j = 0; j < 7; j++) {
                  final date = DateFormat('yyyy-MM-dd').format(
                      DateTime.now().subtract(Duration(days: (index * 7) + j)));
                  if (widget.dailyIntakes.containsKey(date)) {
                    sum += widget.dailyIntakes[date]!;
                    count++;
                  }
                }
                return count > 0
                    ? (sum / count).toDouble()
                    : 0.0; // Cast to double
              }).reversed.toList(),
            ),
          ),
          SizedBox(height: 10),
          _buildGraphContainer(
            title: 'MONTHLY STEPS',
            value:
                '${(monthlySteps.reduce((a, b) => a + b) / monthlySteps.length).round()} steps/week',
            valueColor: Colors.pink,
            chart: StepsActivityChart(
              stepsData: monthlySteps,
              timeFrame: "monthly",
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 170,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade900, width: 1),
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
