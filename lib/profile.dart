import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_2/profile_setupscreen.dart';
import 'notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String userDOB = '';
  String dailyGoal = '';
  String age = '';
  String selectedImage = 'lib/images/profile1.jpg';
  bool locationPermissionGranted = false;
  bool bluetoothPermissionGranted = false;
  bool activityPermissionGranted = false;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    loadProfileDetails();
    _notificationService.initialize();
    checkInitialPermissions();
  }

  Future<void> checkInitialPermissions() async {
    locationPermissionGranted = await Permission.location.isGranted;
    bluetoothPermissionGranted = await Permission.bluetooth.isGranted;
    activityPermissionGranted = await Permission.activityRecognition.isGranted;
    setState(() {});
  }

  Future<void> handlePermissionToggle(
      Permission permission, String permissionName) async {
    // Check the current permission state
    final currentState = await permission.isGranted;

    if (currentState) {
      // Redirect to app settings for manual revocation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "To remove $permissionName permission, please revoke it in app settings."),
          backgroundColor: Colors.orange,
        ),
      );
      openAppSettings();
      return;
    }

    // Request permission if not granted
    final status = await permission.request();

    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$permissionName permission granted."),
          backgroundColor: Colors.green,
        ),
      );
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$permissionName permission denied."),
          backgroundColor: Colors.red,
        ),
      );
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "$permissionName permission permanently denied. Please enable it in settings."),
          backgroundColor: Colors.orange,
        ),
      );
      openAppSettings();
    }

    // Update permission state dynamically
    setState(() {
      if (permission == Permission.location) {
        locationPermissionGranted = status.isGranted;
      } else if (permission == Permission.bluetooth) {
        bluetoothPermissionGranted = status.isGranted;
      } else if (permission == Permission.activityRecognition) {
        activityPermissionGranted = status.isGranted;
      }
    });
  }

  Future<void> loadProfileDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dobString = prefs.getString('userDOB') ?? '';
    DateTime dob = DateTime.tryParse(dobString) ?? DateTime.now();

    setState(() {
      userName = prefs.getString('userName') ?? 'Unknown';
      userDOB = dobString.isNotEmpty ? dobString : 'Not Set';
      dailyGoal = prefs.getString('defaultGoal') ?? '2000';
      selectedImage =
          prefs.getString('profileImage') ?? 'lib/images/profile1.jpg';
      age = calculateAge(dob).toString();
    });
  }

  int calculateAge(DateTime dob) {
    DateTime now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 9, 47, 103),
        toolbarHeight: 70,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Container
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(selectedImage),
                          ),
                          const SizedBox(height: 16.0, width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              profileDetailItem('', userName),
                              profileDetailItem('Age: ', age),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          profileDetailItem('Daily Goal (ml): ', dailyGoal),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSetupScreen(),
                        ),
                      ).then((_) {
                        loadProfileDetails(); // Reload details after editing
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // Notifications Section
            Text(
              'Settings:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: 350,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final List<Map<String, dynamic>> hydrationSchedule = [
                        {
                          "time": const TimeOfDay(hour: 5, minute: 0),
                          "message": "Start your day with a glass of water! \n "
                        },
                        {
                          "time": const TimeOfDay(hour: 8, minute: 0),
                          "message": "Time for your morning hydration boost!"
                        },
                        {
                          "time": const TimeOfDay(hour: 10, minute: 0),
                          "message": "Stay refreshed! Drink some water now."
                        },
                        {
                          "time": const TimeOfDay(hour: 14, minute: 0),
                          "message": "Midday hydration check: Grab a glass!"
                        },
                        {
                          "time": const TimeOfDay(hour: 18, minute: 0),
                          "message": "Evening reminder: Keep hydrating!"
                        },
                        {
                          "time": const TimeOfDay(hour: 21, minute: 0),
                          "message": "End your day right: Drink some water."
                        },
                      ];

                      for (var schedule in hydrationSchedule) {
                        final TimeOfDay time = schedule["time"];
                        final String message = schedule["message"];
                        final now = DateTime.now();
                        final DateTime scheduledDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          time.hour,
                          time.minute,
                        );

                        if (scheduledDateTime.isAfter(now)) {
                          await _notificationService
                              .scheduleHydrationNotification(
                            scheduledDateTime,
                            message,
                          );
                        }
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Hydration notifications with messages scheduled."),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Text("Schedule Hydration Notifications"),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Permissions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 15),
                  permissionToggleRow(
                    "Location\nRequired to obtain weather",
                    locationPermissionGranted,
                    () =>
                        handlePermissionToggle(Permission.location, "Location"),
                  ),
                  const SizedBox(height: 10),
                  permissionToggleRow(
                    "Bluetooth",
                    bluetoothPermissionGranted,
                    () => handlePermissionToggle(
                        Permission.bluetooth, "Bluetooth"),
                  ),
                  const SizedBox(height: 10),
                  permissionToggleRow(
                    "Physical Activity\nRequired for Step count",
                    activityPermissionGranted,
                    () => handlePermissionToggle(
                        Permission.activityRecognition, "Physical Activity"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget permissionToggleRow(
      String label, bool isGranted, VoidCallback onToggle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade800,
          ),
        ),
        Switch(
          value: isGranted,
          onChanged: (value) => onToggle(),
          activeColor: Colors.teal,
        ),
      ],
    );
  }

  Widget profileDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 9, 47, 103),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
      ],
    );
  }
}
