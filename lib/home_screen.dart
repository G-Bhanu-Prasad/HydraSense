import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_2/steps.dart';
import 'package:flutter_application_2/widgets/dayselectorwithslides.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'navbar.dart';
import 'dart:async';

class ProfileDisplayScreen extends StatefulWidget {
  const ProfileDisplayScreen({super.key});

  @override
  ProfileDisplayScreenState createState() => ProfileDisplayScreenState();
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * (3.14159 / 180), // Start from top (-90 degrees)
      progress * 2 * 3.14159, // Convert progress to radians
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      backgroundColor != oldDelegate.backgroundColor ||
      foregroundColor != oldDelegate.foregroundColor ||
      strokeWidth != oldDelegate.strokeWidth;
}

class ProfileDisplayScreenState extends State<ProfileDisplayScreen> {
  int defaultGoal = 2000;
  int dailyGoal = 2000;
  int dailyIntake = 0;
  int streak = 0;
  bool goalMetToday = false;
  bool goalMetYesterday = false;
  late DateTime lastStreakDate;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Map<String, int> dailyIntakes = {};
  Map<String, Map<String, int>> hourlyIntakes = {};
  Map<String, Map<String, int>> hourlySteps = {};
  String userName = '';
  bool isLoading = true;
  String weatherDescription = '';
  double temperature = 0.0;
  String weatherIcon = '';
  int humidity = 0;
  DateTime dop = DateTime.now();
  String city = '';
  int totalGoalsMet = 0;
  int totalIncompleteGoals = 0;
  int totalGoalsIncreased = 0;
  int steps = 0;
  DateTime? lastWaterIntake;
//changed
  @override
  void initState() {
    super.initState();
    _initializeProfileCreationDate().then((_) {
      setState(() {
        isLoading = false;
      });
    });
    loadDailyData();
    loadHourlySteps();
    loadHourlyIntakes();
    _loadDailyGoal();
    getCurrentLocation();
    _requestLocationPermission();
    _requestPhysicalActivityPermission();

    //changed
    _loadLastWaterIntake();
    // Fetch steps and listen for changes
    StepTrackerService().initialize().then((_) {
      setState(() {
        steps = StepTrackerService().dailySteps;
      });

      Timer.periodic(const Duration(seconds: 1), (timer) {
        int currentSteps = StepTrackerService().dailySteps;

        if (currentSteps > steps) {
          int stepsDifference = currentSteps - steps;
          updateHourlySteps(stepsDifference); // Update hourly steps
        }

        setState(() {
          steps = currentSteps;
        });
      });
    });
  }

  Future<void> _reloadHomeScreen() async {
    setState(() {
      isLoading = true;
    });

    try {
      await loadDailyData();
      await _loadDailyGoal();

      final position = await Geolocator.getCurrentPosition();
      await fetchWeather(position.latitude, position.longitude);

      setState(() {});
    } catch (e) {
      debugPrint('Error during reload: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    if (await Permission.location.isDenied ||
        await Permission.location.isRestricted) {
      final status = await Permission.location.request();
      if (status.isGranted) {
        debugPrint("Location permission granted.");
        _autoreloadHomeScreen();
      } else if (status.isDenied) {
        debugPrint("Location permission denied.");
      } else if (status.isPermanentlyDenied) {
        debugPrint(
            "Location permission permanently denied. Please enable it from settings.");
        openAppSettings();
      }
    }
  }

  Future<void> _requestPhysicalActivityPermission() async {
    if (await Permission.activityRecognition.isDenied ||
        await Permission.activityRecognition.isRestricted) {
      final status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        debugPrint("Physical activity permission granted.");
        _autoreloadHomeScreen();
      } else if (status.isDenied) {
        debugPrint("Physical activity permission denied.");
      } else if (status.isPermanentlyDenied) {
        debugPrint(
            "Physical activity permission permanently denied. Please enable it from settings.");
        openAppSettings();
      }
    }
  }

  void _autoreloadHomeScreen() {
    // Replace the current screen with the home screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => ProfileDisplayScreen()),
    );
  }

  Future<void> loadDailyData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
      defaultGoal =
          int.tryParse(prefs.getString('defaultGoal') ?? '2000') ?? 2000;
      String? dailyIntakesJson = prefs.getString('dailyIntakes');
      streak = prefs.getInt('streak') ?? 0;

      String lastUpdateDateStr = prefs.getString('lastUpdateDate') ??
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      lastStreakDate = DateFormat('yyyy-MM-dd').parse(lastUpdateDateStr);

      if (dailyIntakesJson != null) {
        dailyIntakes = Map<String, int>.from(jsonDecode(dailyIntakesJson));
      } else {
        dailyIntakes = {};
      }
      dailyIntake = dailyIntakes[selectedDate] ?? 0;
      totalGoalsMet =
          dailyIntakes.values.where((intake) => intake >= dailyGoal).length;
      totalIncompleteGoals =
          dailyIntakes.values.where((intake) => intake < dailyGoal).length;
      prefs.setInt('totalGoalsMet', totalGoalsMet);
      prefs.setInt('totalIncompleteGoals', totalIncompleteGoals);

      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      goalMetToday = prefs.getString('lastStreakUpdate') == todayStr;

      if (dailyIntake >= dailyGoal && !goalMetToday) {
        checkStreak(prefs);
      }
    });
  }

  Future<void> _loadDailyGoal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double calculatedGoal = await calculateDailyWaterGoal();
    setState(() {
      dailyGoal = (calculatedGoal * 1000).toInt();
    });
    await prefs.setInt('dailyGoal', dailyGoal);
  }

  Future<double> calculateDailyWaterGoal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int age = prefs.getInt('age') ?? 18;
    double height = prefs.getDouble('heightInCm') ?? 170.0;
    double weight = prefs.getDouble('weight') ?? 70.0;
    int steps = prefs.getInt('steps') ?? 0;
    String gender = prefs.getString('gender') ?? 'Male';

    double bmi = weight / ((height / 100) * (height / 100));
    double adjustedBmi =
        bmi + (0.23 * age) - (5.4 * (gender == 'Male' ? 1 : 0));
    double baseIntake = (gender == 'Male') ? 3.0 : 2.7;

    double activityAdjustment = (steps < 5000)
        ? 0.0
        : (steps < 10000)
            ? 0.5
            : 1.0;
    double weightAdjustment = (weight < 60)
        ? 0.5
        : (weight > 90)
            ? 0.5
            : 0.0;
    double ageAdjustment = (age < 30)
        ? 0.7
        : (age > 55)
            ? 0.3
            : 0.5;
    double heightAdjustment = (height > 180)
        ? 0.3
        : (height < 160)
            ? -0.3
            : 0.0;
    double bmiAdjustment = (adjustedBmi >= 30 || adjustedBmi < 18.5)
        ? 0.7
        : (adjustedBmi >= 25)
            ? 0.5
            : 0.0;

    double totalIntake = baseIntake +
        activityAdjustment +
        weightAdjustment +
        ageAdjustment +
        heightAdjustment +
        bmiAdjustment;
    return totalIntake;
  }

  Future<void> _saveDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoal', goal);
  }

  // Add this for date formatting

  Future<void> _increaseDailyGoal() async {
    final TextEditingController inputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E21),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border:
                  Border.all(color: Colors.blue.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.2),
                        Colors.cyan.shade900.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon(Icons.water_drop, color: Colors.blue.shade300),
                      const SizedBox(width: 10),
                      Text(
                        'Adjust Daily Goal',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: inputController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(color: Colors.white),
                        cursorColor: Colors.blue,
                        decoration: InputDecoration(
                          hintText: 'Enter additional ml(e.g 500)',
                          hintStyle:
                              GoogleFonts.inter(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          prefixIcon: Icon(
                            Icons.add_circle_outline,
                            color: Colors.blue.shade300,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Current goal: $dailyGoal ml',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final input = int.tryParse(inputController.text);
                            if (input != null && input > 0) {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();

                              setState(() {
                                dailyGoal += input;
                                totalGoalsIncreased += 1;
                              });

                              // Save updated goal & date
                              prefs.setInt('dailyGoal', dailyGoal);
                              prefs.setInt(
                                  'totalGoalsIncreased', totalGoalsIncreased);
                              prefs.setString(
                                  'lastUpdatedDate',
                                  DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now()));
                            }
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.deniedForever) {
      print("Location services are disabled or permission denied.");
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // meters
      timeLimit: Duration(seconds: 10),
    );

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    fetchWeather(position.latitude, position.longitude);
  }

  Future<void> fetchWeather(double latitude, double longitude) async {
    const apiKey = '3595d9b843533ec2594aff2b8f6ae7a7';
    final url =
        'http://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          weatherDescription = data['weather'][0]['description'];
          temperature = data['main']['temp'];
          humidity = data['main']['humidity'];
          weatherIcon = data['weather'][0]['icon'];
        });

        // Save weather data to SharedPreferences for offline use
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('weatherDescription', weatherDescription);
        await prefs.setDouble('temperature', temperature);
        await prefs.setInt('humidity', humidity);
        await prefs.setString('weatherIcon', weatherIcon);
      } else {
        throw Exception('failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather:$e');

      // If the network is unavailable, fetch from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        weatherDescription =
            prefs.getString('weatherDescription') ?? 'No weather data';
        temperature = prefs.getDouble('temperature') ?? 0.0;
        if (weatherDescription == 'No weather data') {
          humidity = -1; // Special value to indicate no internet
        } else {
          humidity = prefs.getInt('humidity') ?? 0;
        }
        weatherIcon = prefs.getString('weatherIcon') ?? '';
      });
    }
  }

  void checkStreak(SharedPreferences prefs) {
    DateTime today = DateTime.now();
    String todayStr = DateFormat('yyyy-MM-dd').format(today);

    // Increment streak only if it hasn't already been updated for today
    if (!goalMetToday) {
      streak += 1;
      prefs.setInt('streak', streak);
      prefs.setString('lastStreakUpdate', todayStr);
      goalMetToday = true;
    }
  }

  Future<void> updateDailyIntake(int intake) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dailyIntakes[selectedDate] = intake;
    String dailyIntakesJson = jsonEncode(dailyIntakes);
    await prefs.setString('dailyIntakes', dailyIntakesJson);

    if (dailyIntake >= dailyGoal && !goalMetToday) {
      checkStreak(prefs);
    }
  }

  void addWater(int amount) async {
    DateTime today = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(today);

    if (selectedDate != todayDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot update previous day's data"),
          backgroundColor: Colors.pink.shade700,
        ),
      );
      return;
    }

    setState(() {
      dailyIntake += amount;
      dailyIntakes[selectedDate] = dailyIntake;
    });
    //changed
    await updateHourlyIntake(amount);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastWaterIntake', DateTime.now().toIso8601String());
    updateDailyIntake(dailyIntake);
  }

  Future<void> _initializeProfileCreationDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String profileCreationDateString =
        prefs.getString('profileCreationDate') ?? '';

    if (profileCreationDateString.isNotEmpty) {
      dop = DateFormat('yyyy-MM-dd').parse(profileCreationDateString);
    } else {
      dop = DateTime.now();
      await prefs.setString(
          'profileCreationDate', DateFormat('yyyy-MM-dd').format(dop));
    }
    setState(() {});
  }

  String _getHydrationRecommendation() {
    if (temperature <= 20) {
      if (humidity < 40) {
        return 'Cool and dry? Stick with your daily goal of $dailyGoal ml and sip throughout the day to maintain hydration.';
      }
      if (humidity <= 60) {
        return 'Cool and comfortable! Your target of $dailyGoal ml is just right—stay consistent.';
      }
      return 'Cool but humid? Add at least 250 ml to prevent sluggishness and stay refreshed.';
    } else if (temperature <= 25) {
      if (humidity < 40) {
        return 'Warm and dry conditions—boost intake by 500 ml to prevent dehydration symptoms like fatigue.';
      }
      if (humidity <= 60) {
        return 'Mildly warm? Increase intake by 500 ml to support energy levels and prevent mild dehydration.';
      }
      return 'Warm and humid? Increase your intake by 700 ml to counter extra fluid loss.';
    } else if (temperature <= 38) {
      if (humidity < 40) {
        return 'Hot and dry? Increase by 700 ml to replace lost fluids and avoid dehydration risks.';
      }
      if (humidity <= 60) {
        return 'Feeling the heat? Aim for a total of 2750-3000 ml today to sustain optimal hydration.';
      }
      return 'Hot and humid? Increase by at least 700 ml to replenish fluids lost through sweating.';
    } else {
      if (humidity < 40) {
        return 'Extreme heat alert! Boost intake by at least 750 ml and consider electrolyte replenishment if sweating heavily.';
      }
      if (humidity <= 60) {
        return 'High temperatures and sweating? Increase intake by 700-800 ml and stay mindful of hydration cues.';
      }
      return 'Scorching and humid? Increase by 1000 ml or more to avoid overheating and fatigue!';
    }
  }

  String _getHydrationMessage(int steps) {
    if (steps < 1000) {
      return "Low activity - stay hydrated with regular sips.";
    } else if (steps < 5000) {
      return "Moderate activity detected - keep drinking water.";
    } else if (steps < 8000) {
      return "High activity detected - drink more water.";
    } else {
      return "Very active! Ensure you're drinking enough water.";
    }
  }

  String _getLastIntakeMessage() {
    DateTime now = DateTime.now();
    if (lastWaterIntake == null) {
      return "Stay hydrated! Drink some water.";
    }

    Duration difference = now.difference(lastWaterIntake!);
    if (difference.inMinutes < 30) {
      return "Good job! Keep drinking water regularly.";
    } else if (difference.inMinutes < 120) {
      return "You haven't had water in the last hour. Stay hydrated!";
    } else {
      return "You haven't had water in the last 2 hours.";
    }
  }

  Future<void> _loadLastWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastIntakeString = prefs.getString('lastWaterIntake');

    if (lastIntakeString != null) {
      setState(() {
        lastWaterIntake = DateTime.parse(lastIntakeString);
      });
    }
  }

  Widget _buildSleepInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 8),
        Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> loadHourlyIntakes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('hourlyIntakes');
    if (jsonString != null) {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      hourlyIntakes = decoded
          .map((date, hours) => MapEntry(date, Map<String, int>.from(hours)));
    }
  }

  Future<void> updateHourlyIntake(int amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String hour = DateFormat('HH').format(DateTime.now());

    if (!hourlyIntakes.containsKey(date)) {
      hourlyIntakes[date] = {};
    }

    hourlyIntakes[date]![hour] = (hourlyIntakes[date]![hour] ?? 0) + amount;
    await prefs.setString('hourlyIntakes', jsonEncode(hourlyIntakes));
  }

  Future<void> updateHourlySteps(int stepsCount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String hour = DateFormat("HH").format(DateTime.now());
    if (!hourlySteps.containsKey(date)) {
      hourlySteps[date] = {};
    }
    hourlySteps[date]![hour] = (hourlySteps[date]![hour] ?? 0) + stepsCount;
    await prefs.setString('hourlySteps', jsonEncode(hourlySteps));
  }

  Future<void> loadHourlySteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('hourlySteps');
    if (jsonString != null) {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      setState(() {
        hourlySteps = decoded.map(
          (date, hours) => MapEntry(date, Map<String, int>.from(hours)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.02;
    double progress = dailyIntake / dailyGoal;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop(); // This closes the app
        }
      },

      // Prevents going back

      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0xFF0A0E21),
          elevation: 0,
          automaticallyImplyLeading: false,
          //systemOverlayStyle: SystemUiOverlayStyle.light,
          toolbarHeight: 75,
          flexibleSpace: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.lightBlue.withOpacity(0.2),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 10),
                      Text(
                        'HydraSense',
                        style: GoogleFonts.pacifico(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay hydrated, stay healthy!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: RefreshIndicator(
            onRefresh: _reloadHomeScreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade900.withOpacity(0.05),
                      // color: const Color.fromARGB(255, 17, 51, 82)
                      //     .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSleepInfoItem(
                              icon: Icons.local_fire_department_sharp,
                              title: '$streak',
                              subtitle: 'Streak Days',
                            ),
                            _buildSleepInfoItem(
                              icon: Icons.directions_walk_rounded,
                              title: '$steps',
                              subtitle: 'Steps Count',
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSleepInfoItem(
                              icon: Icons.water_drop_outlined,
                              title: humidity == -1 ? 'Turn on' : '$humidity %',
                              subtitle: 'Humidity',
                            ),
                            _buildSleepInfoItem(
                              icon: Icons.wb_sunny_outlined,
                              title: humidity == -1
                                  ? 'Internet'
                                  : '$temperature°C',
                              subtitle: 'Temperature',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Day Selector
                  Container(
                    padding: EdgeInsets.only(left: 8, right: 8),
                    //width: 10,
                    height: screenHeight * 0.14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E21),
                      //borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: DaySelectorWithSlides(
                        isLoading: isLoading,
                        dop: dop,
                        selectedDateTime:
                            DateFormat('yyyy-MM-dd').parse(selectedDate),
                        dailyIntakes: dailyIntakes,
                        dailyGoal: dailyGoal,
                        onDateSelected: (date) {
                          setState(() {
                            selectedDate = date;
                            dailyIntake = dailyIntakes[date] ?? 0;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Circular Progress
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CustomPaint(
                            painter: CircularProgressPainter(
                              progress: progress,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.blue,
                              strokeWidth: 15,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: GoogleFonts.inter(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Daily Goal',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          child: Container(
                            height: 150,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              //color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    //const SizedBox(width: 8),
                                    Text(
                                      'Daily Intake',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // const Icon(
                                    //   Icons.water_drop,
                                    //   color: Colors.blue,
                                    //   size: 15,
                                    // ),
                                  ],
                                ),
                                //const SizedBox(height: 15),
                                Text(
                                  '$dailyIntake ml',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                // const SizedBox(height: 8),
                                Text(
                                  'of $dailyGoal ml goal',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                GestureDetector(
                                  onTap: () => _increaseDailyGoal(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.lightBlue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Adjust Goal',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade900.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tips_and_updates,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Daily Suggestions',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _buildSuggestionItem(
                            icon: Icons.wb_sunny,
                            text: _getHydrationRecommendation(),
                          ),
                          const SizedBox(height: 12),
                          _buildSuggestionItem(
                            icon: Icons.directions_walk,
                            text: _getHydrationMessage(steps),
                          ),
                          const SizedBox(height: 12),
                          _buildSuggestionItem(
                            icon: Icons.access_time,
                            text: _getLastIntakeMessage(),
                          ),
                          const SizedBox(height: 12),
                          _buildSuggestionItem(
                            icon: Icons.trending_up,
                            text: "You're 8 days into your hydration streak!",
                          ),
                        ],
                      ),
                    ),
                  ),
                  //SizedBox(height: screenHeight * 0.001),

                  // Stats Row
                  // Wrap(
                  //   spacing: screenWidth * 0.008,
                  //   runSpacing: screenHeight * 0.02,
                  //   alignment: WrapAlignment.center,
                  //   children: [
                  //     _buildStatCard("Reached", "${(progress * 100).toInt()}%",
                  //         "of Goal", Icons.auto_graph),
                  //     _buildStatCard(
                  //         "Temperature", "$temperature°C", "", Icons.thermostat),
                  //     Container(
                  //       width: screenWidth * 0.29,
                  //       height: screenHeight * 0.11,
                  //       decoration: BoxDecoration(
                  //         color: Colors.blueGrey.shade200,
                  //         borderRadius: BorderRadius.circular(15),
                  //       ),
                  //       child: Center(child: StepsTracker()),
                  //     ),
                  //   ],
                  // ),
                  SizedBox(height: screenHeight * 0.008),

                  // Weather & Increase Goal
                  // _buildWeatherCard(screenWidth, screenHeight),
                ],
              ),
            ),
          ),
        ),

        // Bottom Navigation
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          addWater: () => addWater(250),
          dailyIntakes: dailyIntakes, // Ensure this is passed
        ),
      ),
    );
  }

  Widget _buildWeatherCard(double screenWidth, double screenHeight) {
    return Container(
      padding: const EdgeInsets.only(left: 15, top: 15),
      width: double.infinity,
      height: screenHeight * 0.22,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade200,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          weatherDescription,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        if (weatherIcon.isNotEmpty)
                          Image.network(
                            'https://openweathermap.org/img/w/$weatherIcon.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.cloud_sync,
                                  color: Colors.white, size: 30);
                            },
                          ),
                      ],
                    ),
                    Text(
                      humidity == -1
                          ? 'Turn on Internet'
                          : 'Humidity: $humidity%   ',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey.shade900,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _getHydrationRecommendation(),
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.blueGrey.shade800,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 2, 10, 104)),
                    onPressed: _increaseDailyGoal,
                    child: Text('+ Increase Goal',
                        style: TextStyle(color: Colors.blueGrey.shade100)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 9, 47, 103),
                  borderRadius:
                      const BorderRadius.only(bottomRight: Radius.circular(15)),
                ),
                child: const Icon(Icons.self_improvement_rounded,
                    size: 30, color: Colors.white)),
          ),
        ],
      ),
    );
  }

// Helper function for stat cards
  Widget _buildStatCard(
    String title,
    String value,
    String subtext,
    IconData icon,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.29,
      height: screenHeight * 0.11,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade200,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Center(
            // Ensures text is centered
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevents extra spacing
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(value,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (subtext.isNotEmpty)
                  Text(subtext, style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Positioned(
            bottom: 0, // Adjust to move the icon up/down
            right: 0, // Adjust to move the icon left/right
            child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 9, 47, 103),
                  borderRadius:
                      BorderRadius.only(bottomRight: Radius.circular(15)),
                ),
                child: Icon(icon, size: 20, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
