import 'package:flutter/material.dart';
import 'package:flutter_application_2/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart'; // Ensure this file exists and is correctly set up
import 'package:flutter_application_2/profileedit.dart'; // Your ProfileEditScreen
import 'navbar.dart';
import 'home_screen.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_2/profilescreens.dart/changepass.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/profilescreens.dart/name.dart'; // Import NameInputScreen
import 'package:flutter_application_2/models/user_profile.dart'; // Assuming UserData model is here

// UserData model (if not already defined in models/user_profile.dart)
// class UserData {
//   final String userName;
//   final int age;
//   final String gender;
//   final double height;
//   final double weight;
//   final String email;

//   UserData({
//     required this.userName,
//     required this.age,
//     required this.gender,
//     required this.height,
//     required this.weight,
//     required this.email,
//   });
// }

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserData? _userData; // Holds fetched user profile data
  bool _isLoading = true; // State for loading indicator
  Map<String, int> dailyIntakes = {}; // For BottomNavBar

  // Permission states
  bool _locationPermissionGranted = false;
  bool _activityPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _bluetoothPermissionGranted = false; // Added Bluetooth permission state

  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize(); // Initialize notification service
    _checkAllPermissions(); // Check all permissions
    _loadDailyIntakes(); // For BottomNavBar
    _listenToUserData(); // Listen to real-time user data
  }

  @override
  void dispose() {
    super.dispose();
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

  Future<void> _checkAllPermissions() async {
    // Request and check notification permission
    final notificationStatus = await Permission.notification.request();
    debugPrint("Notification permission status: $notificationStatus");
    setState(() {
      _notificationPermissionGranted = notificationStatus.isGranted;
    });

    // Check location permission
    final locationStatus = await Permission.location.status;
    debugPrint("Location permission status: $locationStatus");
    setState(() {
      _locationPermissionGranted = locationStatus.isGranted;
    });

    // Check activity recognition permission
    final activityStatus = await Permission.activityRecognition.status;
    debugPrint("Activity Recognition permission status: $activityStatus");
    setState(() {
      _activityPermissionGranted = activityStatus.isGranted;
    });

    // Check Bluetooth permission
    final bluetoothStatus = await Permission.bluetooth.status;
    debugPrint("Bluetooth permission status: $bluetoothStatus");
    setState(() {
      _bluetoothPermissionGranted = bluetoothStatus.isGranted;
    });
  }

  // New method to listen to real-time user data from Firestore
  void _listenToUserData() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _firestore.collection('users').doc(uid).snapshots().listen((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        setState(() {
          _userData = UserData(
            userName: data['userName'] ?? 'N/A',
            age: data['age'] ?? 0,
            gender: data['gender'] ?? 'Other',
            height: (data['height'] ?? 0.0).toDouble(),
            weight: (data['weight'] ?? 0.0).toDouble(),
            email: _auth.currentUser?.email ?? 'N/A', // Get email from auth
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _userData = null; // User data not found
          _isLoading = false;
        });
        debugPrint("User data document does not exist for UID: $uid");
      }
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error listening to user data: $error");
      // Optionally, show an error message to the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load profile data: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> handlePermissionToggle(
      Permission permission, String permissionName) async {
    final currentState = await permission.isGranted;

    if (currentState) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "To remove $permissionName permission, please revoke it in app settings."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      openAppSettings();
      return;
    }

    final status = await permission.request();

    if (status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$permissionName permission granted."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (status.isDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$permissionName permission denied."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "$permissionName permission permanently denied. Please enable it in settings."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      openAppSettings();
    }
    // Re-check all permissions to update the UI
    _checkAllPermissions();
  }

  // Modified _deleteAccount to directly delete without email verification
  Future<void> _deleteAccount(BuildContext context) async {
    final user = _auth.currentUser;

    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user is currently signed in.")),
        );
      }
      return;
    }

    // Show confirmation dialog before deletion
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Confirm Account Deletion',
            style: GoogleFonts.inter(color: Colors.white)),
        content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete',
                style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(user.uid).delete();
        debugPrint("User data deleted from Firestore for UID: ${user.uid}");

        // Then delete the user from Firebase Authentication
        await user.delete();
        debugPrint("User deleted from Firebase Auth.");

        // Clear local storage and cancel notifications
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await _notificationService.cancelAllNotifications();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Account successfully deleted.",
                  style: GoogleFonts.inter()),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to the initial sign-up/sign-in page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const NameInputScreen()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'requires-recent-login') {
          // This error can still occur if the user's last sign-in was too long ago.
          // Firebase requires a recent re-authentication for sensitive operations like deletion.
          // The user would need to log out and log back in to refresh their token.
          message =
              "This operation is sensitive and requires recent authentication. Please log out and log in again, then try deleting your account.";
        } else {
          message = "Failed to delete account: ${e.message}";
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(message, style: GoogleFonts.inter()),
                backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("An unexpected error occurred: $e",
                    style: GoogleFonts.inter()),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Helper to get avatar image URL based on gender
  String _getAvatarImageUrl(String? gender) {
    if (gender == 'Male') {
      return 'https://placehold.co/120x120/007bff/ffffff?text=MALE';
    } else if (gender == 'Female') {
      return 'https://placehold.co/120x120/ff69b4/ffffff?text=FEMALE';
    } else {
      return 'https://placehold.co/120x120/6c757d/ffffff?text=OTHER';
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
          title: Text(
            'Profile',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: Colors.blue.shade400),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.withOpacity(0.2),
                              Colors.cyan.shade900.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            // Avatar Image
                            CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  Colors.blue.shade800.withOpacity(0.7),
                              child: ClipOval(
                                child: Image.network(
                                  _getAvatarImageUrl(_userData?.gender),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userData?.userName ?? 'Guest User',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _userData?.email ?? 'No Email',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Displaying other profile data
                                  Text(
                                    'Age: ${_userData?.age ?? 'N/A'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Gender: ${_userData?.gender ?? 'N/A'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Height: ${_userData?.height?.toStringAsFixed(0) ?? 'N/A'} cm',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Weight: ${_userData?.weight?.toStringAsFixed(1) ?? 'N/A'} kg',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.white, size: 24),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileEditScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // General Section
                      _buildSectionHeader('General'),
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
                        child: Column(
                          children: [
                            _buildNotificationSchedulingTile(), // New notification tile
                            _buildListTile(
                              icon: Icons.password_rounded,
                              title: 'Change Password',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ChangePasswordPage()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Permissions Section
                      _buildSectionHeader('Permissions'),
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
                        child: Column(
                          children: [
                            _buildPermissionTile(
                              icon: Icons.notifications_none_outlined,
                              title: 'Notifications',
                              subtitle: 'Enable hydration reminders',
                              value: _notificationPermissionGranted,
                              onChanged: () => handlePermissionToggle(
                                  Permission.notification, "Notification"),
                            ),
                            _buildPermissionTile(
                              icon: Icons.location_on_outlined,
                              title: 'Location',
                              subtitle: 'Required to obtain weather',
                              value: _locationPermissionGranted,
                              onChanged: () => handlePermissionToggle(
                                  Permission.location, "Location"),
                            ),
                            _buildPermissionTile(
                              icon: Icons.directions_run_outlined,
                              title: 'Physical Activity',
                              subtitle: 'Required for Step count',
                              value: _activityPermissionGranted,
                              onChanged: () => handlePermissionToggle(
                                  Permission.activityRecognition,
                                  "Physical Activity"),
                            ),
                            _buildPermissionTile(
                              // Added Bluetooth permission tile
                              icon: Icons.bluetooth_outlined,
                              title: 'Bluetooth',
                              subtitle: 'Required for bottle connection',
                              value: _bluetoothPermissionGranted,
                              onChanged: () => handlePermissionToggle(
                                  Permission.bluetooth, "Bluetooth"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Support Section
                      _buildSectionHeader('Support'),
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
                        child: Column(
                          children: [
                            _buildListTile(
                              icon: Icons.info_outline,
                              title: 'About Us',
                              onTap: () {
                                // Implement navigation to About Us screen
                              },
                            ),
                            _buildListTile(
                              icon: Icons.phone_outlined,
                              title: 'Contact Us',
                              onTap: () {
                                // Implement navigation to Contact Us screen
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Exit Buttons
                      _buildListTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        onTap: () async {
                          bool confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: Text('Confirm Logout',
                                  style:
                                      GoogleFonts.inter(color: Colors.white)),
                              content: Text('Are you sure you want to logout?',
                                  style:
                                      GoogleFonts.inter(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text('Cancel',
                                      style: GoogleFonts.inter(
                                          color: Colors.blue)),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text('Logout',
                                      style:
                                          GoogleFonts.inter(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm) {
                            try {
                              await _auth.signOut();
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();
                              await _notificationService
                                  .cancelAllNotifications(); // Cancel notifications on logout

                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen()), // Navigate to NameInputScreen
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Logout failed: ${e.toString()}",
                                        style: GoogleFonts.inter()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      _buildListTile(
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete Account',
                        textColor: Colors.red.shade300,
                        iconColor: Colors.red.shade300,
                        trailing: null,
                        onTap: () => _deleteAccount(context),
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

  // Helper for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: trailing != null
          ? Text(
              trailing,
              style: GoogleFonts.inter(
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
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white70,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: (_) => onChanged(),
        activeColor: Colors.blue,
        inactiveThumbColor: Colors.grey.shade600,
        inactiveTrackColor: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildNotificationSchedulingTile() {
    return ListTile(
      leading: Icon(Icons.notifications_active_outlined,
          color: Colors.blue.shade300, size: 24),
      title: Text(
        'Schedule Hydration Notifications',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: () async {
        final List<Map<String, dynamic>> hydrationSchedule = [
          {
            "time": const TimeOfDay(hour: 5, minute: 0),
            "message": "Start your day with a glass of water! "
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

        // Clear existing notifications before scheduling new ones to avoid duplicates
        await _notificationService.cancelAllNotifications();

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

          // Only schedule for times in the future today, or for tomorrow if the time has passed today
          if (scheduledDateTime.isAfter(now)) {
            await _notificationService.scheduleHydrationNotification(
              scheduledDateTime,
              message,
            );
          } else {
            // Schedule for tomorrow if the time has already passed today
            final DateTime tomorrowScheduledDateTime = DateTime(
              now.year,
              now.month,
              now.day + 1,
              time.hour,
              time.minute,
            );
            await _notificationService.scheduleHydrationNotification(
              tomorrowScheduledDateTime,
              message,
            );
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hydration notifications scheduled daily!",
                  style: GoogleFonts.inter()),
              backgroundColor: Colors.blue,
            ),
          );
        }
      },
    );
  }
}
