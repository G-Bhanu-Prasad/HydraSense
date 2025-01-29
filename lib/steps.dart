import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepsTracker extends StatefulWidget {
  const StepsTracker({super.key});

  @override
  StepsTrackerState createState() => StepsTrackerState();
}

class StepsTrackerState extends State<StepsTracker> {
  late Stream<StepCount> _stepCountStream;
  String _dailySteps = '?', _distance = '?', _calories = '?';
  int _startSteps = 0;
  DateTime _lastSavedDate = DateTime.now();

  final double _strideLength = 0.78; // Average stride length in meters
  final double _caloriesPerStep = 0.04; // Approximation: 0.04 calories per step

  @override
  void initState() {
    super.initState();
    _initializePedometer();
    _loadSavedData();
  }

  Future<void> _initializePedometer() async {
    bool granted = await _checkActivityRecognitionPermission();
    if (!granted) {
      // Inform user that permission is required.
      return;
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _startSteps = prefs.getInt('startSteps') ?? 0;
      _lastSavedDate =
          DateTime.tryParse(prefs.getString('lastSavedDate') ?? '') ??
              DateTime.now();

      // Reset if a new day has started
      if (!_isSameDay(_lastSavedDate, DateTime.now())) {
        _startSteps = 0;
        _lastSavedDate = DateTime.now();
        prefs.setInt('startSteps', 0);
        prefs.setString('lastSavedDate', _lastSavedDate.toIso8601String());
      }
    });
  }

  Future<bool> _checkActivityRecognitionPermission() async {
    bool granted = await Permission.activityRecognition.isGranted;

    if (!granted) {
      granted = await Permission.activityRecognition.request() ==
          PermissionStatus.granted;
    }

    return granted;
  }

  void _onStepCount(StepCount event) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      if (_startSteps == 0) {
        _startSteps = event.steps;
        prefs.setInt('startSteps', _startSteps);
        prefs.setString('lastSavedDate', DateTime.now().toIso8601String());
      }

      int dailySteps = event.steps - _startSteps;

      // Calculate distance in km
      double distance = (dailySteps * _strideLength) / 1000;

      // Calculate calories burned
      double calories = dailySteps * _caloriesPerStep;

      _dailySteps = dailySteps.toString();
      _distance = distance.toStringAsFixed(2); // Show 2 decimal places
      _calories = calories.toStringAsFixed(2); // Show 2 decimal places
    });
  }

  void _onStepCountError(dynamic error) {
    setState(() {
      _dailySteps = 'Error fetching step count.';
      _distance = '?';
      _calories = '?';
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Steps',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blueGrey.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          _dailySteps,
          style: TextStyle(
              fontSize: 17,
              color: const Color.fromARGB(255, 2, 10, 104),
              fontWeight: FontWeight.bold),
        ),
        //SizedBox(height: 10),

        Text(
          'Cal: $_calories',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blueGrey.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
