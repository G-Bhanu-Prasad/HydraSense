import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTrackerService {
  static final StepTrackerService _instance = StepTrackerService._internal();
  factory StepTrackerService() => _instance;
  StepTrackerService._internal();

  late Stream<StepCount> _stepCountStream;
  int _startSteps = 0;
  int _dailySteps = 0;
  double _distance = 0;
  double _calories = 0;
  DateTime _lastSavedDate = DateTime.now();

  final double _strideLength = 0.78; // meters
  final double _caloriesPerStep = 0.04; // kcal

  int get dailySteps => _dailySteps;
  double get distance => _distance;
  double get calories => _calories;

  Future<void> initialize() async {
    await _loadSavedData();
    bool granted = await _checkActivityRecognitionPermission();
    if (!granted) return;

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _startSteps = prefs.getInt('startSteps') ?? 0;
    _lastSavedDate =
        DateTime.tryParse(prefs.getString('lastSavedDate') ?? '') ??
            DateTime.now();

    if (!_isSameDay(_lastSavedDate, DateTime.now())) {
      _startSteps = 0;
      _lastSavedDate = DateTime.now();
      prefs.setInt('startSteps', 0);
      prefs.setString('lastSavedDate', _lastSavedDate.toIso8601String());
    }
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

    DateTime now = DateTime.now();
    String hourKey = "steps_${now.year}_${now.month}_${now.day}_${now.hour}";
    String hourStartStepsKey =
        "hour_start_steps_${now.year}_${now.month}_${now.day}_${now.hour}";

    // Initialize starting step count for the day
    if (_startSteps == 0) {
      _startSteps = event.steps;
      prefs.setInt('startSteps', _startSteps);
      prefs.setString('lastSavedDate', now.toIso8601String());
    }

    int currentSteps = event.steps;

    // Set today's total steps
    _dailySteps = currentSteps - _startSteps;
    prefs.setInt("steps_${now.year}_${now.month}_${now.day}", _dailySteps);

    _distance = (_dailySteps * _strideLength) / 1000;
    _calories = _dailySteps * _caloriesPerStep;

    // Hourly logic
    int? hourStartSteps = prefs.getInt(hourStartStepsKey);
    if (hourStartSteps == null) {
      // First time in this hour – set the starting steps for this hour
      prefs.setInt(hourStartStepsKey, currentSteps);
      hourStartSteps = currentSteps;
    }

    int hourlySteps = currentSteps - hourStartSteps;

    // Save hourly steps
    prefs.setInt(hourKey, hourlySteps);

    // Optional: Save the hourStartSteps for debugging or reference
    prefs.setInt('lastSavedHour', now.hour);

    // Weekly tracking
    int weekNumber = ((now.day - 1) ~/ 7) + 1;
    String weekKey = "steps_${now.year}_${now.month}_week$weekNumber";
    String lastUpdatedKey = "last_updated_week_$weekNumber";
    String savedDate = prefs.getString(lastUpdatedKey) ?? "";

    String todayStr = now.toIso8601String().split('T')[0];
    if (savedDate != todayStr) {
      int previousWeekSteps = prefs.getInt(weekKey) ?? 0;
      prefs.setInt(weekKey, previousWeekSteps + _dailySteps);
      prefs.setString(lastUpdatedKey, todayStr);
    }
  }

  void _onStepCountError(dynamic error) {
    _dailySteps = 0;
    _distance = 0;
    _calories = 0;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
