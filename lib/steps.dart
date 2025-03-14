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

    if (_startSteps == 0) {
      _startSteps = event.steps;
      prefs.setInt('startSteps', _startSteps);
      prefs.setString('lastSavedDate', DateTime.now().toIso8601String());
    }

    _dailySteps = event.steps - _startSteps;
    _distance = (_dailySteps * _strideLength) / 1000;
    _calories = _dailySteps * _caloriesPerStep;

    // Store hourly steps
    DateTime now = DateTime.now();
    String hourKey = "steps_${now.year}_${now.month}_${now.day}_${now.hour}";
    int lastSavedHour = prefs.getInt('lastSavedHour') ?? now.hour;

    if (lastSavedHour != now.hour) {
      prefs.setInt(hourKey, 0); // Reset hourly steps
      prefs.setInt('lastSavedHour', now.hour);
    }

    int previousSteps = prefs.getInt(hourKey) ?? 0;
    prefs.setInt(hourKey, previousSteps + (_dailySteps - previousSteps));

    // Store weekly steps (corrected)
    int weekNumber = ((now.day - 1) ~/ 7) + 1; // Week 1 to Week 4
    String weekKey = "steps_${now.year}_${now.month}_week$weekNumber";
    String lastUpdatedKey = "last_updated_week_$weekNumber";
    String savedDate = prefs.getString(lastUpdatedKey) ?? "";

    if (savedDate != now.toIso8601String().split('T')[0]) {
      int previousWeekSteps = prefs.getInt(weekKey) ?? 0;
      prefs.setInt(weekKey, previousWeekSteps + _dailySteps);
      prefs.setString(lastUpdatedKey, now.toIso8601String().split('T')[0]);
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
