import 'package:flutter/material.dart';
import 'package:flutter_application_2/profile.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_2/steps.dart';
import 'package:flutter_application_2/widgets/dayselectorwithslides.dart';
import 'package:flutter_application_2/bottle.dart';
import 'package:flutter_application_2/analysis.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

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
  int steps = StepTrackerService().dailySteps;
  double distance = StepTrackerService().distance;
  double calories = StepTrackerService().calories;

  @override
  void initState() {
    super.initState();
    //_initializeDOB();
    _initializeProfileCreationDate().then((_) {
      setState(() {
        isLoading = false;
      });
    });
    loadDailyData();
    _loadDailyGoal();
    getCurrentLocation();
    _requestLocationPermission();
    _requestPhysicalActivityPermission();
    StepTrackerService().initialize();
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

      if (dailyIntake >= defaultGoal && !goalMetToday) {
        checkStreak(prefs);
      }
    });
  }

  Future<void> _loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();

    // Get today's date in 'YYYY-MM-DD' format
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];
    final String savedDate = prefs.getString('selectedDate') ?? todayDate;

    if (savedDate != todayDate) {
      setState(() {
        dailyGoal = defaultGoal;
      });

      // Save new date and reset goal
      await prefs.setString('selectedDate', todayDate);
      await prefs.setInt('dailyGoal', defaultGoal);
    } else {
      setState(() {
        dailyGoal = prefs.getInt('dailyGoal') ?? defaultGoal; // Load saved goal
      });
    }
  }

  Future<void> _saveDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoal', goal);
  }

  Future<void> _increaseDailyGoal() async {
    final TextEditingController inputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Increase Daily Goal',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 47, 103),
                fontWeight: FontWeight.w500,
              )),
          backgroundColor: Colors.blueGrey.shade200,
          content: TextField(
            controller: inputController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter additional ml(e.g., 500)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: const Color.fromARGB(255, 229, 53, 94),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final input = int.tryParse(inputController.text);
                if (input != null && input > 0) {
                  setState(() {
                    dailyGoal += input;
                    totalGoalsIncreased += 1;
                  });
                  _saveDailyGoal(dailyGoal);
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setInt('totalGoalsIncreased', totalGoalsIncreased);
                  prefs.setInt('dailyGoal', dailyGoal);
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color.fromARGB(255, 9, 47, 103),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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

    if (dailyIntake >= defaultGoal && !goalMetToday) {
      checkStreak(prefs);
    }
  }

  void addWater(int amount) {
    DateTime today = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(today);

    if (selectedDate != todayDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot update previous day's data")),
      );
      return;
    }

    setState(() {
      dailyIntake += amount;
      dailyIntakes[selectedDate] = dailyIntake;
    });
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
      if (humidity < 40)
        return 'Cool and dry? Stick with 2000 ml today and sip regularly.';
      if (humidity <= 60)
        return 'Cool and comfy! 2000 ml is perfect for today.';
      return 'Cool but humid? Aim for 2250 ml to stay energized.';
    } else if (temperature <= 25) {
      if (humidity < 40)
        return 'Warm and dry? Boost to 2500 ml to avoid fatigue.';
      if (humidity <= 60)
        return 'A bit warm? Drink 2500 ml to keep your energy up.';
      return 'Warm and humid? Go for 2750 ml to stay hydrated.';
    } else if (temperature <= 30) {
      if (humidity < 40)
        return 'Hot and dry? 2750 ml will protect against dehydration.';
      if (humidity <= 60) return 'Feeling the heat? Drink 2750-3000 ml today.';
      return 'Hot and sticky? Aim for 3000 ml to replace lost fluids.';
    } else {
      if (humidity < 40)
        return 'Extreme heat! At least 3250 ml to stay hydrated.';
      if (humidity <= 60)
        return 'Hot and sweaty? 3250-3500 ml is needed today.';
      return 'Humid and scorching? Drink 3500 ml to stay cool and energized!';
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.02;
    double progress = dailyIntake / dailyGoal;

    return PopScope(
      canPop: false, // Prevents going back

      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
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
                      color: Colors.blueGrey.withOpacity(0.1),
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
                              subtitle: 'Strak Days',
                            ),
                            _buildSleepInfoItem(
                              icon: Icons.directions_walk_rounded,
                              title: '$steps',
                              subtitle: 'Step Count',
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
                        defaultGoal: defaultGoal,
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
                        color: Colors.blueGrey.withOpacity(0.1),
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
                            text: "High activity detected - drink more water",
                          ),
                          const SizedBox(height: 12),
                          _buildSuggestionItem(
                            icon: Icons.access_time,
                            text: "You haven't had water in the last 2 hours",
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
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF0A0E21),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.blueGrey.shade400,
          onTap: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BottlePage()),
                );
                break;
              case 2:
                addWater(250);
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AnalysisPage(dailyIntakes: dailyIntakes),
                  ),
                );
                break;
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.water_drop_rounded), label: 'Bottle'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline), label: 'Add'),
            BottomNavigationBarItem(
                icon: Icon(Icons.analytics), label: 'Analysis'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
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
