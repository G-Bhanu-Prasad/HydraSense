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
import 'package:flutter/services.dart'; // Import this if not already present
import 'navbar.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_application_2/distanceprovider.dart';
import 'package:flutter_application_2/ble_helper.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore

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

class ProfileDisplayScreenState extends State<ProfileDisplayScreen>
    with WidgetsBindingObserver {
  int defaultGoal = 2000;
  int dailyGoal = 2000;
  int dailyIntake = 0;
  int streak = 0;
  bool goalMetToday = false;
  late DateTime lastStreakDate;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Map<String, int> dailyIntakes = {}; // This will primarily be for display
  Map<String, Map<String, int>> hourlyIntakes = {};
  Map<String, Map<String, int>> hourlySteps = {};
  String userName = '';
  bool isLoading = true; // Set to true initially
  String weatherDescription = '';
  double temperature = 0.0;
  String weatherIcon = '';
  int humidity = 0;
  DateTime dop = DateTime.now(); // Date of Profile creation
  int totalGoalsMet = 0;
  int totalIncompleteGoals = 0;
  int totalGoalsIncreased = 0;
  int steps = 0;
  DateTime? lastWaterIntake;
  int? _lastAddedDistance; // Track the last distance added to prevent duplicate additions
  late DistanceProvider _distanceProvider;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId; // To store the current user's UID
  StreamSubscription<DocumentSnapshot>? _userDocSubscription; // Listener for user data

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer for app lifecycle

    // Listen for auth state changes to get the user ID
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        debugPrint('initState: User ID set to $_userId. Initializing data...');
        _initializeData(); // Initialize data once user is authenticated
      } else {
        debugPrint("initState: User is signed out. Attempting anonymous sign-in...");
        _auth.signInAnonymously().then((_) {
          setState(() {
            _userId = _auth.currentUser?.uid;
          });
          debugPrint('initState: Signed in anonymously. User ID: $_userId. Initializing data...');
          _initializeData();
        }).catchError((e) {
          debugPrint("initState: Error signing in anonymously: $e");
          setState(() {
            isLoading = false; // Stop loading if auth fails
          });
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _distanceProvider = Provider.of<DistanceProvider>(context, listen: false);
      _distanceProvider.addListener(_handleDistanceChange);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    if (mounted) {
      _distanceProvider.removeListener(_handleDistanceChange);
    }
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _userDocSubscription?.cancel(); // Cancel the Firestore listener
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (_userId == null) {
      setState(() {
        isLoading = false; // Stop loading if user ID is not available
      });
      debugPrint('_initializeData: _userId is null, stopping initialization.');
      return;
    }

    debugPrint('_initializeData: Starting data initialization for user $_userId');
    _listenToDailyDataFromFirestore();

    await _initializeProfileCreationDate();
    await loadHourlySteps();
    await loadHourlyIntakes();
    await _loadDailyGoal();
    await getCurrentLocation();
    await _requestLocationPermission();
    await _requestPhysicalActivityPermission();
    BLEHelper.autoReconnectToLastDevice(context);
    await _loadLastWaterIntake();

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

  void _handleDistanceChange() {
    final distance = _distanceProvider.distance;
    if (distance != null && distance > 0 && distance != _lastAddedDistance) {
      _lastAddedDistance = distance;
      debugPrint('DistanceProvider: Detected distance $distance. Adding water.');
      addWater(distance);
    }
  }

  Future<void> _reloadHomeScreen() async {
    setState(() {
      isLoading = true; // Show loading indicator on refresh
    });
    debugPrint('_reloadHomeScreen: Reloading home screen.');
    await _initializeData();
    final position = await Geolocator.getCurrentPosition();
    await fetchWeather(position.latitude, position.longitude);
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ProfileDisplayScreen()),
    );
  }

  void _listenToDailyDataFromFirestore() {
    if (_userId == null) {
      debugPrint('_listenToDailyDataFromFirestore: _userId is null, cannot listen.');
      return;
    }

    _userDocSubscription?.cancel(); // Cancel previous subscription if any
    debugPrint('_listenToDailyDataFromFirestore: Setting up Firestore listener for user $_userId');

    _userDocSubscription = _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((DocumentSnapshot userDoc) async {
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        debugPrint('Firestore Listener: Received data for user $_userId. Data: $userData');

        setState(() {
          userName = userData['userName'] ?? 'User';
          defaultGoal = userData['defaultGoal'] ?? 2000;
          streak = userData['streak'] ?? 0;
          totalGoalsMet = userData['totalGoalsMet'] ?? 0;
          totalIncompleteGoals = userData['totalIncompleteGoals'] ?? 0;
          totalGoalsIncreased = userData['totalGoalsIncreased'] ?? 0;

          Map<String, dynamic> firestoreDailyIntakes =
              userData['dailyIntakes'] ?? {};
          dailyIntakes = Map<String, int>.from(firestoreDailyIntakes
              .map((key, value) => MapEntry(key, value as int)));

          dailyIntake = dailyIntakes[selectedDate] ?? 0;
          debugPrint('Firestore Listener setState: dailyIntake updated to $dailyIntake for selectedDate $selectedDate');

          String lastUpdateDateStr = userData['lastUpdateDate'] ??
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          lastStreakDate = DateFormat('yyyy-MM-dd').parse(lastUpdateDateStr);

          String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          goalMetToday = userData['lastStreakUpdate'] == todayStr;

          if (dailyIntake >= dailyGoal && !goalMetToday) {
            checkStreak();
          }

          if (isLoading) {
            isLoading = false;
            debugPrint('Firestore Listener setState: isLoading set to false.');
          }
        });
      } else {
        debugPrint('Firestore Listener: User document does not exist. Creating initial document.');
        await _firestore.collection('users').doc(_userId).set({
          'userName': 'User',
          'defaultGoal': 2000,
          'dailyIntakes': {},
          'streak': 0,
          'lastUpdateDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'lastStreakUpdate': '',
          'totalGoalsMet': 0,
          'totalIncompleteGoals': 0,
          'totalGoalsIncreased': 0,
          'profileCreationDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'dailyGoal': dailyGoal,
          'hourlyIntakes': {},
          'hourlySteps': {},
          'lastWaterIntake': null,
        });
        debugPrint('New user document created in Firestore.');
      }
    }, onError: (error) {
      debugPrint('Error listening to user document: $error');
      loadDailyDataFromSharedPreferences();
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> loadDailyDataFromSharedPreferences() async {
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
        checkStreak();
      }
      isLoading = false;
      debugPrint('Loaded data from SharedPreferences. dailyIntake: $dailyIntake');
    });
  }

  Future<void> _loadDailyGoal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double calculatedGoal = await calculateDailyWaterGoal();
    setState(() {
      dailyGoal = (calculatedGoal * 1000).toInt();
    });
    if (_userId != null) {
      await _firestore.collection('users').doc(_userId).update({
        'dailyGoal': dailyGoal,
      }).catchError((e) => debugPrint("Error updating dailyGoal in Firestore: $e"));
    }
    await prefs.setInt('dailyGoal', dailyGoal);
    debugPrint('_loadDailyGoal: Daily goal set to $dailyGoal ml.');
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
                              setState(() {
                                dailyGoal += input;
                                totalGoalsIncreased += 1;
                              });

                              if (_userId != null) {
                                await _firestore.collection('users').doc(_userId).update({
                                  'dailyGoal': dailyGoal,
                                  'totalGoalsIncreased': totalGoalsIncreased,
                                  'lastUpdateDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                });
                                debugPrint('_increaseDailyGoal: Updated dailyGoal to $dailyGoal in Firestore.');
                              }
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              prefs.setInt('dailyGoal', dailyGoal);
                              prefs.setInt('totalGoalsIncreased', totalGoalsIncreased);
                              prefs.setString('lastUpdateDate', DateFormat('yyyy-MM-dd').format(DateTime.now()));
                              debugPrint('_increaseDailyGoal: Updated dailyGoal to $dailyGoal in SharedPreferences.');
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
      debugPrint("Location services are disabled or permission denied.");
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
        debugPrint('Weather fetched: $weatherDescription, $temperature°C');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('weatherDescription', weatherDescription);
        await prefs.setDouble('temperature', temperature);
        await prefs.setInt('humidity', humidity);
        await prefs.setString('weatherIcon', weatherIcon);
      } else {
        throw Exception('failed to load weather data');
      }
    } catch (e) {
      debugPrint('Error fetching weather:$e');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        weatherDescription =
            prefs.getString('weatherDescription') ?? 'No weather data';
        temperature = prefs.getDouble('temperature') ?? 0.0;
        if (weatherDescription == 'No weather data') {
          humidity = -1;
        } else {
          humidity = prefs.getInt('humidity') ?? 0;
        }
        weatherIcon = prefs.getString('weatherIcon') ?? '';
      });
      debugPrint('Loaded weather from SharedPreferences: $weatherDescription, $temperature°C');
    }
  }

  void checkStreak() async {
    if (_userId == null) return;

    DateTime today = DateTime.now();
    String todayStr = DateFormat('yyyy-MM-dd').format(today);

    if (!goalMetToday) {
      setState(() {
        streak += 1;
        goalMetToday = true;
      });
      await _firestore.collection('users').doc(_userId).update({
        'streak': streak,
        'lastStreakUpdate': todayStr,
      }).catchError((e) => debugPrint("Error updating streak in Firestore: $e"));
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt('streak', streak);
      prefs.setString('lastStreakUpdate', todayStr);
      debugPrint('Streak updated to $streak. goalMetToday: $goalMetToday');
    }
  }

  Future<void> updateDailyIntake(int intake) async {
    if (_userId == null) return;

    // Update the local map first
    dailyIntakes[selectedDate] = intake;

    await _firestore.collection('users').doc(_userId).update({
      'dailyIntakes.$selectedDate': intake,
    }).catchError((e) => debugPrint("Error updating dailyIntake in Firestore: $e"));
    debugPrint('updateDailyIntake: Firestore updated dailyIntakes.$selectedDate to $intake');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dailyIntakesJson = jsonEncode(dailyIntakes);
    await prefs.setString('dailyIntakes', dailyIntakesJson);
    debugPrint('updateDailyIntake: SharedPreferences updated dailyIntakes to $dailyIntakesJson');

    if (intake >= dailyGoal && !goalMetToday) { // Use 'intake' parameter directly
      checkStreak();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void addWater(int amount) async {
    DateTime today = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(today);

    debugPrint('addWater: Attempting to add $amount ml. selectedDate: $selectedDate, todayDate: $todayDate');

    if (selectedDate != todayDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot update previous day's data"),
          backgroundColor: Colors.pink.shade700,
        ),
      );
      debugPrint('addWater: Blocked update for past date.');
      return;
    }

    // Calculate the new daily intake based on the current value in dailyIntakes map
    // The UI will update when the Firestore listener receives the new data.
    int newDailyIntake = (dailyIntakes[selectedDate] ?? 0) + amount;
    debugPrint('addWater: Calculated new dailyIntake: $newDailyIntake');

    // Update last water intake time locally and persist
    lastWaterIntake = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastWaterIntake', DateTime.now().toIso8601String());
    debugPrint('addWater: lastWaterIntake updated in SharedPreferences.');

    // Trigger Firestore updates. The UI will react via the Firestore listener.
    await updateHourlyIntake(amount);
    await updateDailyIntake(newDailyIntake); // Pass the calculated new value
    debugPrint('addWater: updateDailyIntake and updateHourlyIntake called for persistence.');
  }

  Future<void> _initializeProfileCreationDate() async {
    if (_userId == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_userId).get();

    if (userDoc.exists && userDoc.data() != null && (userDoc.data() as Map<String, dynamic>).containsKey('profileCreationDate')) {
      String profileCreationDateString = userDoc['profileCreationDate'];
      dop = DateFormat('yyyy-MM-dd').parse(profileCreationDateString);
      debugPrint('_initializeProfileCreationDate: Loaded DOP from Firestore: $dop');
    } else {
      dop = DateTime.now();
      await _firestore.collection('users').doc(_userId).set({
        'profileCreationDate': DateFormat('yyyy-MM-dd').format(dop),
      }, SetOptions(merge: true)).catchError((e) => debugPrint("Error setting profileCreationDate in Firestore: $e"));
      debugPrint('_initializeProfileCreationDate: Set new DOP to Firestore: $dop');
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

  String _getGoalProgressMessage(int currentIntake, int goal) {
    if (goal <= 0) {
      return "Set a daily goal to track your progress!";
    }
    double progressPercentage = (currentIntake / goal) * 100;
    if (progressPercentage >= 100) {
      return "Fantastic! You've met your daily hydration goal. Keep it up!";
    } else if (progressPercentage >= 75) {
      return "Almost there! You're close to reaching your daily goal.";
    } else if (progressPercentage >= 50) {
      return "Halfway point! Keep going to hit your daily hydration target.";
    } else if (progressPercentage > 0) {
      return "Good start! Remember to keep sipping towards your goal.";
    } else {
      return "Let's get started! Begin tracking your water intake for today.";
    }
  }

  Future<void> _loadLastWaterIntake() async {
    if (_userId == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_userId).get();
    if (userDoc.exists && userDoc.data() != null && (userDoc.data() as Map<String, dynamic>).containsKey('lastWaterIntake')) {
      String? lastIntakeString = userDoc['lastWaterIntake'];
      if (lastIntakeString != null) {
        setState(() {
          lastWaterIntake = DateTime.parse(lastIntakeString);
        });
        debugPrint('_loadLastWaterIntake: Loaded lastWaterIntake from Firestore: $lastWaterIntake');
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? lastIntakeString = prefs.getString('lastWaterIntake');
      if (lastIntakeString != null) {
        setState(() {
          lastWaterIntake = DateTime.parse(lastIntakeString);
        });
        debugPrint('_loadLastWaterIntake: Loaded lastWaterIntake from SharedPreferences: $lastWaterIntake');
      }
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
    if (_userId == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_userId).get();
    if (userDoc.exists && userDoc.data() != null && (userDoc.data() as Map<String, dynamic>).containsKey('hourlyIntakes')) {
      Map<String, dynamic> decoded = userDoc['hourlyIntakes'];
      setState(() {
        hourlyIntakes = decoded
            .map((date, hours) => MapEntry(date, Map<String, int>.from(hours)));
      });
      debugPrint('loadHourlyIntakes: Loaded hourlyIntakes from Firestore.');
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString('hourlyIntakes');
      if (jsonString != null) {
        Map<String, dynamic> decoded = jsonDecode(jsonString);
        setState(() {
          hourlyIntakes = decoded
              .map((date, hours) => MapEntry(date, Map<String, int>.from(hours)));
        });
        debugPrint('loadHourlyIntakes: Loaded hourlyIntakes from SharedPreferences.');
      }
    }
  }

  Future<void> updateHourlyIntake(int amount) async {
    if (_userId == null) return;

    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String hour = DateFormat('HH').format(DateTime.now());

    if (!hourlyIntakes.containsKey(date)) {
      hourlyIntakes[date] = {};
    }

    hourlyIntakes[date]![hour] = (hourlyIntakes[date]![hour] ?? 0) + amount;

    await _firestore.collection('users').doc(_userId).update({
      'hourlyIntakes.$date.$hour': hourlyIntakes[date]![hour],
    }).catchError((e) => debugPrint("Error updating hourlyIntake in Firestore: $e"));
    debugPrint('updateHourlyIntake: Firestore updated hourlyIntakes.$date.$hour to ${hourlyIntakes[date]![hour]}');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hourlyIntakes', jsonEncode(hourlyIntakes));
    debugPrint('updateHourlyIntake: SharedPreferences updated hourlyIntakes.');
  }

  Future<void> updateHourlySteps(int stepsCount) async {
    if (_userId == null) return;

    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String hour = DateFormat("HH").format(DateTime.now());
    if (!hourlySteps.containsKey(date)) {
      hourlySteps[date] = {};
    }
    hourlySteps[date]![hour] = (hourlySteps[date]![hour] ?? 0) + stepsCount;

    await _firestore.collection('users').doc(_userId).update({
      'hourlySteps.$date.$hour': hourlySteps[date]![hour],
    }).catchError((e) => debugPrint("Error updating hourlySteps in Firestore: $e"));
    debugPrint('updateHourlySteps: Firestore updated hourlySteps.$date.$hour to ${hourlySteps[date]![hour]}');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hourlySteps', jsonEncode(hourlySteps));
    debugPrint('updateHourlySteps: SharedPreferences updated hourlySteps.');
  }

  Future<void> loadHourlySteps() async {
    if (_userId == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_userId).get();
    if (userDoc.exists && userDoc.data() != null && (userDoc.data() as Map<String, dynamic>).containsKey('hourlySteps')) {
      Map<String, dynamic> decoded = userDoc['hourlySteps'];
      setState(() {
        hourlySteps = decoded.map(
          (date, hours) => MapEntry(date, Map<String, int>.from(hours)),
        );
      });
      debugPrint('loadHourlySteps: Loaded hourlySteps from Firestore.');
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString('hourlySteps');
      if (jsonString != null) {
        Map<String, dynamic> decoded = jsonDecode(jsonString);
        setState(() {
          hourlySteps = decoded.map(
            (date, hours) => MapEntry(date, Map<String, int>.from(hours)),
          );
        });
        debugPrint('loadHourlySteps: Loaded hourlySteps from SharedPreferences.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double progress = dailyGoal > 0 ? dailyIntake / dailyGoal : 0.0;
    final distance = context.watch<DistanceProvider>().distance;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0xFF0A0E21),
          elevation: 0,
          automaticallyImplyLeading: false,
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
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: RefreshIndicator(
            onRefresh: _reloadHomeScreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Consumer<ConnectionProvider>(
                    builder: (context, connectionProvider, child) {
                      return Container(
                        width: double.infinity,
                        color: connectionProvider.isConnected
                            ? Colors.green[100]
                            : Colors.red[100],
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              connectionProvider.isConnected
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: connectionProvider.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              connectionProvider.isConnected
                                  ? "Bottle Connected"
                                  : "Bottle Not Connected",
                              style: TextStyle(
                                color: connectionProvider.isConnected
                                    ? Colors.green[800]
                                    : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade900.withOpacity(0.05),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    height: screenHeight * 0.14,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A0E21),
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
                            debugPrint('DaySelector: Selected date changed to $selectedDate. dailyIntake: $dailyIntake');
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

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
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Daily Intake',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$dailyIntake ml',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
                            icon: Icons.show_chart,
                            text: _getGoalProgressMessage(dailyIntake, dailyGoal),
                          ),
                          const SizedBox(height: 12),
                          _buildSuggestionItem(
                            icon: Icons.trending_up,
                            text: "You're $streak days into your hydration streak!",
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    distance != null ? 'Distance: $distance cm' : 'Waiting...',
                    style: const TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          addWater: () => addWater(250),
          dailyIntakes: dailyIntakes,
        ),
      ),
    );
  }
}
