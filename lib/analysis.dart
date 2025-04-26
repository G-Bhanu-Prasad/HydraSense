import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_2/graph.dart';
import 'package:flutter_application_2/piechart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navbar.dart';
import 'home_screen.dart';
import 'stepsgraph.dart';
import 'dart:convert';
import 'dart:async';

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
  int selectedDayIntake = 0;

  @override
  void initState() {
    super.initState();
    _loadTotalGoalsIncreased();
    _loadStepsData();
    _loadSelectedDayIntake();
  }

  // Load the water intake for the selected date
  Future<void> _loadSelectedDayIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Try to get from the provided dailyIntakes map first
    int intake = widget.dailyIntakes[dateKey] ?? 0;

    // If not found, try to get from SharedPreferences as fallback
    if (intake == 0) {
      // Try to load from hourlyIntakes to get the day's total
      String? jsonString = prefs.getString('hourlyIntakes');
      if (jsonString != null) {
        try {
          Map<String, dynamic> decoded = json.decode(jsonString);
          if (decoded.containsKey(dateKey)) {
            Map<String, dynamic> dayData = decoded[dateKey];
            int dayTotal = 0;
            dayData.forEach((hour, value) {
              dayTotal += (value as int);
            });
            intake = dayTotal;
          }
        } catch (e) {
          // Handle JSON parsing error
          print("Error parsing hourlyIntakes: $e");
        }
      }

      // If still not found, check for a direct daily record
      if (intake == 0) {
        intake = prefs.getInt('water_intake_$dateKey') ?? 0;
      }
    }

    setState(() {
      selectedDayIntake = intake;
    });
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
      _loadStepsDataForDate(picked);
      _loadSelectedDayIntake();
    }
  }

  // Navigate to previous day
  void _previousDay() {
    DateTime newDate = selectedDate.subtract(Duration(days: 1));
    setState(() {
      selectedDate = newDate;
    });
    _loadStepsDataForDate(newDate);
    _loadSelectedDayIntake();
  }

  // Navigate to next day
  void _nextDay() {
    DateTime newDate = selectedDate.add(Duration(days: 1));
    // Don't allow selecting future dates
    if (newDate.isBefore(DateTime.now().add(Duration(days: 1)))) {
      setState(() {
        selectedDate = newDate;
      });
      _loadStepsDataForDate(newDate);
      _loadSelectedDayIntake();
    }
  }

  // Load steps data for a specific date
  Future<void> _loadStepsDataForDate(DateTime date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load hourly steps for the selected date
    List<int> hourly = List.generate(24, (index) {
      String key = "steps_${date.year}_${date.month}_${date.day}_$index";
      return prefs.getInt(key) ?? 0;
    });

    setState(() {
      hourlySteps = hourly;
    });
  }

  Future<void> _loadStepsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load hourly steps for the current selected date
    _loadStepsDataForDate(selectedDate);

    // Load weekly data
    DateTime now = DateTime.now();
    List<int> weekly = [];
    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String key = "steps_${date.year}_${date.month}_${date.day}";
      int dailyTotal = 0;

      // Calculate daily total by summing hourly values
      for (int hour = 0; hour < 24; hour++) {
        String hourlyKey = "steps_${date.year}_${date.month}_${date.day}_$hour";
        dailyTotal += prefs.getInt(hourlyKey) ?? 0;
      }

      // Use the calculated total or fall back to the daily stored value
      weekly.add(dailyTotal > 0 ? dailyTotal : (prefs.getInt(key) ?? 0));
    }

    // Load monthly data
    List<int> monthly = List.generate(4, (week) {
      String key = "steps_${now.year}_${now.month}_week${week + 1}";
      return prefs.getInt(key) ?? 0;
    });

    setState(() {
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
    // Calculate average hourly intake for the selected date
    final averageHourlyIntake = (selectedDayIntake / 24).toStringAsFixed(1);

    // Calculate average hourly steps
    final int totalDailySteps =
        hourlySteps.fold(0, (sum, steps) => sum + steps);
    final String averageHourlySteps =
        totalDailySteps > 0 ? (totalDailySteps / 24).toStringAsFixed(1) : "0";

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left, color: Colors.white),
                      onPressed: _previousDay,
                    ),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Text(
                        DateFormat('EEEE dd').format(selectedDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.cyan.shade500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_right, color: Colors.white),
                      onPressed: _nextDay,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          _buildGraphContainer(
            title: 'HOURLY AVERAGE WATER INTAKE',
            value: '$averageHourlyIntake ml/hr',
            valueColor: Colors.blue,
            chart: HourlyWaterIntakeChart(selectedDate: selectedDate),
          ),
          SizedBox(height: 10),
          _buildGraphContainer(
            title: 'HOURLY STEPS',
            value: '$averageHourlySteps steps/hr',
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
    // Calculate monthly average water intake
    final monthlyAverageIntake = widget.dailyIntakes.values.isEmpty
        ? 0
        : widget.dailyIntakes.values.reduce((a, b) => a + b) /
            widget.dailyIntakes.length;

    // Calculate monthly average steps
    final int totalMonthlySteps =
        monthlySteps.fold(0, (sum, steps) => sum + steps);
    final double averageWeeklySteps =
        monthlySteps.isNotEmpty ? totalMonthlySteps / monthlySteps.length : 0;

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
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          _buildGraphContainer(
            title: 'MONTHLY AVERAGE WATER INTAKE',
            value: '${monthlyAverageIntake.round()} ml',
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
                return count > 0 ? (sum / count).toDouble() : 0.0;
              }).reversed.toList(),
            ),
          ),
          SizedBox(height: 10),
          _buildGraphContainer(
            title: 'MONTHLY STEPS',
            value: '${averageWeeklySteps.round()} steps/week',
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
