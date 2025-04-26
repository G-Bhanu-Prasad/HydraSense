import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class MonthlyWaterIntakeChart extends StatelessWidget {
  final List<double> weeklyAverages;

  const MonthlyWaterIntakeChart({Key? key, required this.weeklyAverages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double maxY =
        (weeklyAverages.isNotEmpty) ? weeklyAverages.reduce(max) : 1000;
    double midY = maxY / 2;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  List<String> weeks = ["Week 1", "Week 2", "Week 3", "Week 4"];
                  return (value < weeks.length)
                      ? Text(weeks[value.toInt()],
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12))
                      : SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return Text('0 ml',
                        style: TextStyle(fontSize: 10, color: Colors.white));
                  } else if (value == midY) {
                    return Text('${midY.toInt()} ',
                        style: TextStyle(fontSize: 10, color: Colors.white));
                  } else if (value == maxY) {
                    return Text('${maxY.toInt()} ',
                        style: TextStyle(fontSize: 10, color: Colors.white));
                  }
                  return SizedBox.shrink();
                },
                interval: maxY / 2,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: weeklyAverages.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  gradient: LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent]),
                  width: 15,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class HourlyWaterIntakeChart extends StatefulWidget {
  final DateTime? selectedDate;

  const HourlyWaterIntakeChart({super.key, this.selectedDate});

  @override
  _HourlyWaterIntakeChartState createState() => _HourlyWaterIntakeChartState();
}

class _HourlyWaterIntakeChartState extends State<HourlyWaterIntakeChart> {
  List<int> hourlyIntakes = List.filled(24, 0);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHourlyIntakes();
  }

  @override
  void didUpdateWidget(HourlyWaterIntakeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the selected date has changed
    if (widget.selectedDate != oldWidget.selectedDate) {
      _loadHourlyIntakes();
    }
  }

  Future<void> _loadHourlyIntakes() async {
    setState(() {
      isLoading = false;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Use the selected date if provided, otherwise use today's date
    DateTime dateToLoad = widget.selectedDate ?? DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateToLoad);

    String? jsonString = prefs.getString('hourlyIntakes');

    if (jsonString != null) {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      Map<String, int> dayHourly = decoded[formattedDate] != null
          ? Map<String, int>.from(decoded[formattedDate])
          : {};

      setState(() {
        hourlyIntakes = List.generate(
          24,
          (hour) => dayHourly[hour.toString().padLeft(2, '0')] ?? 0,
        );
        isLoading = false;
      });
    } else {
      setState(() {
        hourlyIntakes = List.filled(24, 0);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    double highestIntake =
        hourlyIntakes.reduce((a, b) => a > b ? a : b).toDouble();
    double maxY = (highestIntake <= 0)
        ? 500
        : (highestIntake + 200); // Set a buffer above highest bar
    double midY = maxY / 2;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxY, // Ensure bars fit within the graph
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1, // Show labels every 3 hours for readability
                getTitlesWidget: (value, meta) {
                  if (value % 4 == 0) {
                    // Show only labels at 4-hour intervals
                    String text = "";
                    switch (value.toInt()) {
                      case 0:
                        text = "12AM";
                        break;
                      case 4:
                        text = "4AM";
                        break;
                      case 8:
                        text = "8AM";
                        break;
                      case 12:
                        text = "12PM";
                        break;
                      case 16:
                        text = "4PM";
                        break;
                      case 20:
                        text = "8PM";
                        break;
                      default:
                        text = "";
                    }
                    return Text(
                      text,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const Text('0 ',
                        style: TextStyle(fontSize: 10, color: Colors.white));
                  } else if (value == midY) {
                    return Text('${midY.toInt()} ',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white));
                  } else if (value == maxY) {
                    return Text('${maxY.toInt()} ',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white));
                  }
                  return const SizedBox.shrink();
                },
                interval: maxY / 2,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          barGroups: hourlyIntakes.asMap().entries.map((entry) {
            int hour = entry.key;
            int value = entry.value;

            return BarChartGroupData(
              x: hour,
              barRods: [
                BarChartRodData(
                  toY: value.clamp(0, maxY).toDouble(),
                  // Prevent bars from exceeding maxY
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.lightBlueAccent],
                  ),
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class HourlyStepsChart extends StatefulWidget {
  final DateTime? selectedDate;

  const HourlyStepsChart({super.key, this.selectedDate});

  @override
  _HourlyStepsChartState createState() => _HourlyStepsChartState();
}

class _HourlyStepsChartState extends State<HourlyStepsChart> {
  List<int> hourlySteps = List.filled(24, 0); // Initialize with zeros
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHourlySteps();
  }

  @override
  void didUpdateWidget(HourlyStepsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the selected date has changed
    if (widget.selectedDate != oldWidget.selectedDate) {
      _loadHourlySteps();
    }
  }

  Future<void> _loadHourlySteps() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Use the selected date if provided, otherwise use today's date
    DateTime dateToLoad = widget.selectedDate ?? DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateToLoad);

    // First try to load from hourlySteps JSON
    String? jsonString = prefs.getString('hourlySteps');
    bool foundData = false;

    if (jsonString != null) {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      Map<String, int> dayHourly = decoded[formattedDate] != null
          ? Map<String, int>.from(decoded[formattedDate])
          : {};

      if (dayHourly.isNotEmpty) {
        setState(() {
          hourlySteps = List.generate(
            24,
            (hour) => dayHourly[hour.toString().padLeft(2, '0')] ?? 0,
          );
          foundData = true;
        });
      }
    }

    // If no data found in JSON, try loading from individual keys
    if (!foundData) {
      List<int> steps = List.filled(24, 0);
      for (int hour = 0; hour < 24; hour++) {
        String key =
            "steps_${dateToLoad.year}_${dateToLoad.month}_${dateToLoad.day}_$hour";
        steps[hour] = prefs.getInt(key) ?? 0;
      }

      setState(() {
        hourlySteps = steps;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    double highestSteps =
        hourlySteps.reduce((a, b) => a > b ? a : b).toDouble();
    double maxY =
        (highestSteps <= 0) ? 1000 : highestSteps * 1.2; // Give extra space

    double midY = maxY / 2;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1, // Show labels every 3 hours for readability
                getTitlesWidget: (value, meta) {
                  if (value % 4 == 0) {
                    // Show only labels at 4-hour intervals
                    String text = "";
                    switch (value.toInt()) {
                      case 0:
                        text = "12AM";
                        break;
                      case 4:
                        text = "4AM";
                        break;
                      case 8:
                        text = "8AM";
                        break;
                      case 12:
                        text = "12PM";
                        break;
                      case 16:
                        text = "4PM";
                        break;
                      case 20:
                        text = "8PM";
                        break;
                      default:
                        text = "";
                    }
                    return Text(
                      text,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: midY,
                getTitlesWidget: (value, _) {
                  if (value == 0) {
                    return const Text('0',
                        style: TextStyle(fontSize: 10, color: Colors.white));
                  } else if (value == midY) {
                    return Text('${midY.toInt()}',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white));
                  } else if (value == maxY) {
                    return Text('${maxY.toInt()}',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          barGroups: hourlySteps.asMap().entries.map((entry) {
            int hour = entry.key;
            int value = entry.value;

            return BarChartGroupData(
              x: hour,
              barRods: [
                BarChartRodData(
                  toY: value.clamp(0, maxY).toDouble(), // Prevent overflow
                  gradient: const LinearGradient(
                    colors: [Colors.pink, Colors.pinkAccent],
                  ),
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
