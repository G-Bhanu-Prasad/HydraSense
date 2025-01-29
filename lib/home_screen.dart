import 'package:flutter/material.dart';
import 'package:flutter_application_2/profile.dart';
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

class ProfileDisplayScreen extends StatefulWidget {
  const ProfileDisplayScreen({super.key});

  @override
  ProfileDisplayScreenState createState() => ProfileDisplayScreenState();
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
    final savedDate = prefs.getString('selectedDate') ?? selectedDate;

    // Check if the saved date is different from the current date
    if (savedDate != selectedDate) {
      setState(() {
        dailyGoal = defaultGoal; // Reset dailyGoal to defaultGoal
      });
      // Save the new date and reset the goal in SharedPreferences
      await prefs.setString('selectedDate', selectedDate);
      await prefs.setInt('dailyGoal', defaultGoal);
    } else {
      setState(() {
        dailyGoal =
            prefs.getInt('dailyGoal') ?? defaultGoal; // Load saved dailyGoal
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.02;

    double progress = dailyIntake / dailyGoal;

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade100,
      appBar: AppBar(
        toolbarHeight: screenHeight * 0.1,
        backgroundColor: const Color.fromARGB(255, 2, 10, 104),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello $userName',
              style: TextStyle(
                color: Colors.blueGrey.shade100,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Welcome Back!',
              style: TextStyle(
                color: Colors.blueGrey.shade100,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: screenHeight * 0.03, right: screenWidth * 0.04),
                child: Row(
                  children: [
                    const SizedBox(width: 3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 15),
                        Row(children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors
                                .red.shade400, //Color.fromARGB(255, 2, 32, 78),
                            size: 30,
                          ),
                          Text(
                            '$streak',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ])
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadHomeScreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.005),
                Container(
                  width: screenWidth * 1.0,
                  height: screenHeight * 0.14,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade200,
                    borderRadius: BorderRadius.circular(15),
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
                SizedBox(height: screenHeight * 0.01),
                Container(
                  width: screenWidth * 1.0,
                  //height: screenHeight * 0.39,
                  height: 210,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 20,
                            backgroundColor: Colors.blueGrey.shade600,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 9, 47, 103),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            //const SizedBox(height: 70),
                            Text(
                              '$dailyIntake',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.blueGrey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '/$dailyGoal ml',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly, // Align both containers
                  children: [
                    Container(
                      width: screenWidth * 0.30,
                      height: screenHeight * 0.11,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                //const SizedBox(height: 10),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 5),
                                      Text(
                                        'Reached',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.blueGrey.shade900,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            '${(progress * 100).toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color.fromARGB(
                                                  255, 2, 10, 104),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'of Goal',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blueGrey.shade900,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 2, 10, 104),
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_graph,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: screenWidth * 0.30,
                      height: screenHeight * 0.11,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Temperature',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.blueGrey.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.thermostat,
                                      color: Colors.blue.shade500,
                                    ),
                                    Text(
                                      '$temperature°C',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 2, 10, 104),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 2, 10, 104),
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: const Icon(
                                Icons.wb_sunny_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: screenWidth * 0.30,
                      height: screenHeight * 0.11,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: StepsTracker(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: EdgeInsets.only(left: 15, top: 15),
                  width: screenWidth * 1.0,
                  height: screenHeight * 0.20,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade200,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      // Main content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      weatherDescription,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (weatherIcon.isNotEmpty)
                                      Image.network(
                                        'https://openweathermap.org/img/w/$weatherIcon.png', // Use the dynamic weather icon
                                        width: 30,
                                        height: 30,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          // Fallback icon in case of an error
                                          return const Icon(Icons.cloud_sync,
                                              color: Colors.white, size: 30);
                                        },
                                      ),
                                  ],
                                ),
                                Text(
                                  humidity == -1
                                      ? 'Turn on Internet'
                                      : 'Humidity: $humidity%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding:
                                EdgeInsets.only(top: 5, right: 5, bottom: 5),
                            width: screenWidth *
                                0.9, // Adjusted width to fit suggestion text
                            child: Text(
                              temperature <= 20
                                  ? (humidity < 40
                                      ? 'Cool and dry? Stick with 2000 ml today and sip water regularly to stay hydrated and energetic.'
                                      : (humidity <= 60
                                          ? 'Cool and comfy! 2000 ml of water is perfect to keep you refreshed and ready for the day.'
                                          : 'Cool but humid? Aim for 2250 ml to stay energized and beat the hidden effects of humidity.'))
                                  : (temperature > 20 && temperature <= 25
                                      ? (humidity < 40
                                          ? 'Warm and dry? Boost to 2500 ml to avoid fatigue and stay sharp all day long.'
                                          : (humidity <= 60
                                              ? 'A bit warm? Drink 2500 ml of water to keep your energy levels steady and body refreshed.'
                                              : 'Warm and humid? Go for 2750 ml to replace lost fluids and keep yourself feeling great.'))
                                      : (temperature > 25 && temperature <= 30
                                          ? (humidity < 40
                                              ? 'Hot and dry weather calls for 2750 ml to protect yourself from dehydration. Take small sips throughout the day to stay cool.'
                                              : (humidity <= 60
                                                  ? 'Feeling the heat? Drink 2750-3000 ml to stay hydrated & maintain energy levels..'
                                                  : 'Hot and sticky? Aim for 3000 ml to combat sweat loss and feel your best all day.'))
                                          : (temperature > 30
                                              ? (humidity < 40
                                                  ? 'Extreme heat and dryness demand at least 3250 ml to keep your body functioning well....'
                                                  : (humidity <= 60
                                                      ? 'Hot and sweaty? Recharge with 3250-3500 ml to feel energized and avoid dehydration.'
                                                      : 'Humid and scorching? Drink 3500 ml to stay cool and conquer the day with ease!'))
                                              : 'Stay hydrated to perform your best and feel amazing!'))),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blueGrey.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow
                                  .ellipsis, // Prevent text overflow
                            ),
                          ),
                        ],
                      ),

                      // Elevated Button at the bottom
                      Positioned(
                        bottom: 10, // Adjust as needed
                        left: 15,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 2, 10, 104),
                          ),
                          onPressed: _increaseDailyGoal,
                          child: Text(
                            '+ Increase Goal',
                            style: TextStyle(
                              color: Colors.blueGrey.shade100,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 2, 10, 104),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.zero,
                              topLeft: Radius.circular(10),
                            ),
                          ),
                          child: const Icon(Icons.self_improvement_rounded,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blueGrey.shade100,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 9, 47, 103),
        unselectedItemColor: Colors.blueGrey.shade400,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BottlePage(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_rounded),
            label: 'Bottle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
