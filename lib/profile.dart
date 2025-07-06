import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';
import 'package:flutter_application_2/profileedit.dart';
import 'navbar.dart';
import 'home_screen.dart';
import 'dart:convert';
// import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_2/profilescreens.dart/changepass.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  int _selectedAge = 18;
  double heightInCm = 170;
  double _selectedWeight = 50.0;
  String? _selectedActivity;
  String selectedImage = 'lib/images/image.png';
  bool locationPermissionGranted = false;
  bool bluetoothPermissionGranted = false;
  bool activityPermissionGranted = false;
  Map<String, int> dailyIntakes = {};

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    loadProfileDetails();
    _notificationService.initialize();
    checkInitialPermissions();
    _loadDailyIntakes();
  }

  Future<void> _loadDailyIntakes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dailyIntakesJson = prefs.getString('dailyIntakes');

    if (dailyIntakesJson != null) {
      setState(() {
        dailyIntakes = Map<String, int>.from(jsonDecode(dailyIntakesJson));
      });
    }
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

    // Try to load from SharedPreferences first (offline support)
    String savedName = prefs.getString('userName') ?? 'Unknown';

    setState(() {
      userName = savedName;
    });

    // Then try fetching from Firestore (online)
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final fetchedName = data?['userName'] ?? 'Unknown';

          setState(() {
            userName = fetchedName;
          });

          // Save it for offline use next time
          await prefs.setString('userName', fetchedName);
        }
      }
    } catch (e) {
      print("Error fetching userName from Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileDisplayScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: const Color(0xFF0A0E21),
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileDisplayScreen()),
              );
            },
          ),
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Row(
                  children: [
                    // Container(
                    //   width: 60,
                    //   height: 60,
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       begin: Alignment.topLeft,
                    //       end: Alignment.bottomRight,
                    //       colors: [
                    //         const Color.fromARGB(255, 10, 33, 210)
                    //             .withOpacity(0.3),
                    //         Colors.cyan.withOpacity(0.8),
                    //       ],
                    //     ),
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: ClipRRect(
                    //     borderRadius: BorderRadius.circular(30),
                    //     child: Image.asset(
                    //       selectedImage,
                    //       fit: BoxFit.cover,
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Hello',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () {
                        // Navigate to the profile screen
// In your ProfilePage, replace the navigation with:
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileEditScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // General Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'General',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.lightBlue.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // Aligns children to the left
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final List<Map<String, dynamic>>
                                  hydrationSchedule = [
                                {
                                  "time": const TimeOfDay(hour: 5, minute: 0),
                                  "message":
                                      "Start your day with a glass of water! \n "
                                },
                                {
                                  "time": const TimeOfDay(hour: 8, minute: 0),
                                  "message":
                                      "Time for your morning hydration boost!"
                                },
                                {
                                  "time": const TimeOfDay(hour: 10, minute: 0),
                                  "message":
                                      "Stay refreshed! Drink some water now."
                                },
                                {
                                  "time": const TimeOfDay(hour: 14, minute: 0),
                                  "message":
                                      "Midday hydration check: Grab a glass!"
                                },
                                {
                                  "time": const TimeOfDay(hour: 18, minute: 0),
                                  "message": "Evening reminder: Keep hydrating!"
                                },
                                {
                                  "time": const TimeOfDay(hour: 21, minute: 0),
                                  "message":
                                      "End your day right: Drink some water."
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
                            child:
                                const Text("Schedule Hydration Notifications"),
                          ),
                          _buildListTile(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Physical Information',
                            trailing:
                                '$_selectedWeight kg, ${heightInCm.toStringAsFixed(0)} cm',
                            onTap: () {},
                          ),
                          _buildListTile(
                            icon: Icons.auto_graph_outlined,
                            title: 'Hydration Score',
                            trailing: _selectedActivity ?? 'Not set',
                            onTap: () {},
                          ),
                          _buildListTile(
                            icon: Icons.password_rounded,
                            title: 'Change Password',
                            trailing: null,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChangePasswordPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Permissions Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Permissions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildPermissionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: 'Required to obtain weather',
                  value: locationPermissionGranted,
                  onChanged: () =>
                      handlePermissionToggle(Permission.location, "Location"),
                ),
                // _buildPermissionTile(
                //   icon: Icons.bluetooth_outlined,
                //   title: 'Bluetooth',
                //   value: bluetoothPermissionGranted,
                //   onChanged: () =>
                //       handlePermissionToggle(Permission.bluetooth, "Bluetooth"),
                // ),
                _buildPermissionTile(
                  icon: Icons.directions_run_outlined,
                  title: 'Physical Activity',
                  subtitle: 'Required for Step count',
                  value: activityPermissionGranted,
                  onChanged: () => handlePermissionToggle(
                      Permission.activityRecognition, "Physical Activity"),
                ),

                const SizedBox(height: 16),

                // Support Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                // _buildListTile(
                //   icon: Icons.headset_mic_outlined,
                //   title: 'Support',
                //   onTap: () {},
                // ),
                _buildListTile(
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.phone_outlined,
                  title: 'Contact Us',
                  onTap: () {},
                ),

                const SizedBox(height: 16),

                // Exit Button
                _buildListTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () async {
                    // Show confirmation dialog
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('Confirm Logout',
                            style: TextStyle(color: Colors.white)),
                        content: const Text('Are you sure you want to logout?',
                            style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.blue)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Logout',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm) {
                      try {
                        // 1. Sign out from Firebase
                        await FirebaseAuth.instance.signOut();

                        // 2. Clear shared preferences
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.clear();

                        // 3. Navigate to login screen and remove all routes
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Logout failed: ${e.toString()}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 4,
          dailyIntakes: dailyIntakes,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: trailing != null
          ? Text(
              trailing,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: onTap,
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required VoidCallback onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: (_) => onChanged(),
        activeColor: Colors.blue,
      ),
    );
  }
}
