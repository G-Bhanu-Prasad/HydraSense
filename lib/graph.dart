import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'dart:async'; // For StreamSubscription

// Monthly Water Intake Chart (StatelessWidget)
// This widget displays weekly average water intake as a bar chart.
class MonthlyWaterIntakeChart extends StatelessWidget {
  final List<double> weeklyAverages;

  const MonthlyWaterIntakeChart({Key? key, required this.weeklyAverages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the maximum Y-axis value for the chart.
    // If no data, default to 1000ml, otherwise use the max average + a buffer.
    double maxY = (weeklyAverages.isNotEmpty)
        ? weeklyAverages.reduce(max) * 1.2 // Add 20% buffer above max
        : 1000;
    double midY = maxY / 2; // Calculate midpoint for Y-axis labels

    return SizedBox(
      height: 300, // Fixed height for the chart container
      child: BarChart(
        BarChartData(
          maxY: maxY, // Set the calculated max Y-axis value
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xff37434d),
                strokeWidth: 0.8,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: const Color(0xff37434d),
                strokeWidth: 0.8,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30, // Space reserved for titles
                getTitlesWidget: (value, meta) {
                  // Labels for weeks (Week 1, Week 2, etc.)
                  List<String> weeks = ["Week 1", "Week 2", "Week 3", "Week 4"];
                  return (value >= 0 && value < weeks.length)
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            weeks[value.toInt()],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12),
                          ),
                        )
                      : const SizedBox.shrink(); // Hide labels outside range
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // Space reserved for titles
                getTitlesWidget: (value, meta) {
                  // Labels for Y-axis (0, midY, maxY)
                  if (value == 0) {
                    return const Text('0 ml',
                        style: TextStyle(fontSize: 10, color: Colors.white));
                  } else if (value == midY) {
                    return Text('${midY.toInt()} ml',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white));
                  } else if (value == maxY) {
                    return Text('${maxY.toInt()} ml',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white));
                  }
                  return const SizedBox.shrink();
                },
                interval: midY, // Show labels at 0, midY, and maxY
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: weeklyAverages.asMap().entries.map((entry) {
            // Create bar groups for each weekly average
            return BarChartGroupData(
              x: entry.key, // X-axis value (index of the week)
              barRods: [
                BarChartRodData(
                  toY: entry.value, // Y-axis value (average intake)
                  gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent]),
                  width: 15,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          // Optional: Add touch interaction for the chart
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              //tooltipBgColor: Colors.blueGrey.shade700, // Corrected parameter name
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String weekLabel = "Week ${group.x + 1}";
                return BarTooltipItem(
                  '$weekLabel\n${rod.toY.toInt()} ml', // Combined text
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  // Removed 'widget' parameter as it's not supported by BarTooltipItem
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Hourly Water Intake Chart (StatefulWidget)
// This widget displays hourly water intake data from Firestore.
class HourlyWaterIntakeChart extends StatefulWidget {
  final DateTime? selectedDate; // The date for which to display hourly data

  const HourlyWaterIntakeChart({super.key, this.selectedDate});

  @override
  _HourlyWaterIntakeChartState createState() => _HourlyWaterIntakeChartState();
}

class _HourlyWaterIntakeChartState extends State<HourlyWaterIntakeChart> {
  List<int> hourlyIntakes = List.filled(24, 0); // Initialize with zeros for 24 hours
  bool isLoading = true; // State to manage loading indicator

  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  String? _userId; // Current user's UID
  StreamSubscription<DocumentSnapshot>? _userDocSubscription; // Firestore listener subscription

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes to get the user ID
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        debugPrint('HourlyWaterIntakeChart: User ID set to $_userId. Loading hourly intakes...');
        _loadHourlyIntakes(); // Load data once user is authenticated
      } else {
        debugPrint('HourlyWaterIntakeChart: User is signed out. Attempting anonymous sign-in...');
        _auth.signInAnonymously().then((_) {
          setState(() {
            _userId = _auth.currentUser?.uid;
          });
          debugPrint('HourlyWaterIntakeChart: Signed in anonymously. User ID: $_userId. Loading hourly intakes...');
          _loadHourlyIntakes();
        }).catchError((e) {
          debugPrint('HourlyWaterIntakeChart: Error signing in anonymously: $e');
          setState(() {
            isLoading = false; // Stop loading if auth fails
          });
        });
      }
    });
  }

  @override
  void didUpdateWidget(HourlyWaterIntakeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if the selected date has changed
    if (widget.selectedDate != oldWidget.selectedDate) {
      debugPrint('HourlyWaterIntakeChart: Selected date changed. Reloading hourly intakes.');
      _loadHourlyIntakes();
    }
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel(); // Cancel the Firestore listener to prevent memory leaks
    super.dispose();
  }

  // Loads hourly intake data from Firestore
  Future<void> _loadHourlyIntakes() async {
    if (_userId == null) {
      debugPrint('HourlyWaterIntakeChart: _userId is null, cannot load hourly intakes.');
      setState(() {
        isLoading = false;
        hourlyIntakes = List.filled(24, 0); // Clear data if no user
      });
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator while fetching
    });

    // Use the selected date if provided, otherwise use today's date
    DateTime dateToLoad = widget.selectedDate ?? DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateToLoad);

    // Cancel previous subscription before setting up a new one
    _userDocSubscription?.cancel();

    // Set up a real-time listener for the user's document
    _userDocSubscription = _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((DocumentSnapshot userDoc) {
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> firestoreHourlyIntakes = userData['hourlyIntakes'] ?? {};

        // Get the hourly data for the specific formattedDate
        Map<String, int> dayHourly = firestoreHourlyIntakes[formattedDate] != null
            ? Map<String, int>.from(firestoreHourlyIntakes[formattedDate])
            : {};

        setState(() {
          // Populate hourlyIntakes list for all 24 hours
          hourlyIntakes = List.generate(
            24,
            (hour) => dayHourly[hour.toString().padLeft(2, '0')] ?? 0,
          );
          isLoading = false; // Data loaded, hide loading indicator
          debugPrint('HourlyWaterIntakeChart: Loaded hourly intakes for $formattedDate from Firestore. Data: $hourlyIntakes');
        });
      } else {
        // If user document or hourlyIntakes field doesn't exist, set to zeros
        setState(() {
          hourlyIntakes = List.filled(24, 0);
          isLoading = false;
          debugPrint('HourlyWaterIntakeChart: User document or hourlyIntakes field not found. Setting hourlyIntakes to zeros.');
        });
      }
    }, onError: (error) {
      debugPrint('HourlyWaterIntakeChart: Error listening to Firestore for hourly intakes: $error');
      setState(() {
        hourlyIntakes = List.filled(24, 0); // On error, clear data
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator()); // Show loading indicator
    }

    // Calculate max Y-axis value for the chart based on current data
    double highestIntake =
        hourlyIntakes.reduce((a, b) => a > b ? a : b).toDouble();
    double maxY = (highestIntake <= 0)
        ? 500 // Default max if no intake
        : (highestIntake + (highestIntake * 0.2)); // Add 20% buffer above highest bar
    double midY = maxY / 2; // Calculate midpoint for Y-axis labels

    return SizedBox(
      height: 300, // Fixed height for the chart container
      child: BarChart(
        BarChartData(
          maxY: maxY, // Set the calculated max Y-axis value
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xff37434d),
                strokeWidth: 0.8,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: const Color(0xff37434d),
                strokeWidth: 0.8,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1, // Show labels for every hour initially
                getTitlesWidget: (value, meta) {
                  // Show labels at 4-hour intervals for readability
                  if (value % 4 == 0) {
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
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    );
                  }
                  return const SizedBox.shrink(); // Hide other labels
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: midY, // Show labels at 0, midY, and maxY
                getTitlesWidget: (value, _) {
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
              x: hour, // X-axis value (hour of the day)
              barRods: [
                BarChartRodData(
                  toY: value.clamp(0, maxY).toDouble(), // Ensure bars fit within maxY
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.lightBlueAccent],
                  ),
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              // Optional: Add touch interaction for individual bars
              showingTooltipIndicators: [], // Initially no tooltips
            );
          }).toList(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              //tooltipBgColor: Colors.blueGrey.shade700, // Corrected parameter name
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String hourLabel = "${group.x.toInt().toString().padLeft(2, '0')}:00";
                return BarTooltipItem(
                  '$hourLabel\n${rod.toY.toInt()} ml', // Combined text
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  // Removed 'widget' parameter
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Hourly Steps Chart (StatefulWidget)
// This widget displays hourly steps data from SharedPreferences.
// This widget remains largely unchanged as the request was for water intake.
class HourlyStepsChart extends StatefulWidget {
  final DateTime? selectedDate;

  const HourlyStepsChart({super.key, this.selectedDate});

  @override
  _HourlyStepsChartState createState() => _HourlyStepsChartState();
}

class _HourlyStepsChartState extends State<HourlyStepsChart> {
  List<int> hourlySteps = List.filled(24, 0); // Initialize with zeros
  bool isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  String? _userId; // Current user's UID
  StreamSubscription<DocumentSnapshot>? _userDocSubscription; // Firestore listener subscription

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes to get the user ID
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        debugPrint('HourlyStepsChart: User ID set to $_userId. Loading hourly steps...');
        _loadHourlySteps(); // Load data once user is authenticated
      } else {
        debugPrint('HourlyStepsChart: User is signed out. Attempting anonymous sign-in...');
        _auth.signInAnonymously().then((_) {
          setState(() {
            _userId = _auth.currentUser?.uid;
          });
          debugPrint('HourlyStepsChart: Signed in anonymously. User ID: $_userId. Loading hourly steps...');
          _loadHourlySteps();
        }).catchError((e) {
          debugPrint('HourlyStepsChart: Error signing in anonymously: $e');
          setState(() {
            isLoading = false; // Stop loading if auth fails
          });
        });
      }
    });
  }

  @override
  void didUpdateWidget(HourlyStepsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the selected date has changed
    if (widget.selectedDate != oldWidget.selectedDate) {
      debugPrint('HourlyStepsChart: Selected date changed. Reloading hourly steps.');
      _loadHourlySteps();
    }
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel(); // Cancel the Firestore listener
    super.dispose();
  }

  Future<void> _loadHourlySteps() async {
    if (_userId == null) {
      debugPrint('HourlyStepsChart: _userId is null, cannot load hourly steps.');
      setState(() {
        isLoading = false;
        hourlySteps = List.filled(24, 0); // Clear data if no user
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    DateTime dateToLoad = widget.selectedDate ?? DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateToLoad);

    _userDocSubscription?.cancel(); // Cancel previous subscription

    _userDocSubscription = _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((DocumentSnapshot userDoc) {
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> firestoreHourlySteps = userData['hourlySteps'] ?? {};

        Map<String, int> dayHourly = firestoreHourlySteps[formattedDate] != null
            ? Map<String, int>.from(firestoreHourlySteps[formattedDate])
            : {};

        setState(() {
          hourlySteps = List.generate(
            24,
            (hour) => dayHourly[hour.toString().padLeft(2, '0')] ?? 0,
          );
          isLoading = false;
          debugPrint('HourlyStepsChart: Loaded hourly steps for $formattedDate from Firestore. Data: $hourlySteps');
        });
      } else {
        setState(() {
          hourlySteps = List.filled(24, 0);
          isLoading = false;
          debugPrint('HourlyStepsChart: User document or hourlySteps field not found. Setting hourlySteps to zeros.');
        });
      }
    }, onError: (error) {
      debugPrint('HourlyStepsChart: Error listening to Firestore for hourly steps: $error');
      setState(() {
        hourlySteps = List.filled(24, 0);
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xff37434d),
                strokeWidth: 0.8,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: const Color(0xff37434d),
                strokeWidth: 0.8,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1, // Show labels every 3 hours for readability
                getTitlesWidget: (value, meta) {
                  if (value % 4 == 0) {
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
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
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
              showingTooltipIndicators: [],
            );
          }).toList(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              //tooltipBgColor: Colors.blueGrey.shade700, // Corrected parameter name
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String hourLabel = "${group.x.toInt().toString().padLeft(2, '0')}:00";
                return BarTooltipItem(
                  '$hourLabel\n${rod.toY.toInt()} steps', // Combined text
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  // Removed 'widget' parameter
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
