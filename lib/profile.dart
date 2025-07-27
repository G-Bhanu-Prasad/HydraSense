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
        backgroundColor: const Color(0xFF1E2A3A),
        title: Text('Confirm Account Deletion',
            style: GoogleFonts.inter(color: Colors.white)),
        content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
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
          backgroundColor: const Color(0xFF0A0E21),
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileDisplayScreen()),
              );
            },
          ),
          title: Text(
            'Profile',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: Colors.teal),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Greeting Section
                    _buildUserGreetingSection(),
                    const SizedBox(height: 32),

                    // General Section
                    _buildSectionHeader('General'),
                    const SizedBox(height: 16),
                    _buildGeneralSection(),
                    const SizedBox(height: 32),

                    // Permissions Section
                    _buildSectionHeader('Permissions'),
                    const SizedBox(height: 16),
                    _buildPermissionsSection(),
                    const SizedBox(height: 32),

                    // Support Section
                    _buildSectionHeader('Support'),
                    const SizedBox(height: 16),
                    _buildSupportSection(),
                    const SizedBox(height: 0),

                    // Logout Section
                    _buildLogoutSection(),
                  ],
                ),
              ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 4,
          dailyIntakes: dailyIntakes,
        ),
      ),
    );
  }

  // User Greeting Section
  /// Builds the user greeting section with welcome message and profile edit option
  Widget _buildUserGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting text
        Text(
          'Hello',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),

        // User name and edit profile row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // User name display
            Expanded(
              child: Text(
                _userData?.userName ?? 'Guest User',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 12),

            // Edit profile button
            _buildEditProfileButton(),
          ],
        ),
      ],
    );
  }

  /// Builds the edit profile button with proper styling and navigation
  Widget _buildEditProfileButton() {
    return GestureDetector(
      onTap: _navigateToProfileEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Profile',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates to the profile edit screen
  void _navigateToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
      ),
    );
  }

  // General Section
  Widget _buildGeneralSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.2),
            Colors.lightBlue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Schedule Hydration Notifications Button
          Container(
            margin: const EdgeInsets.all(20),
            child: Material(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () async {
                  await _scheduleHydrationNotifications();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Schedule Hydration Notifications',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Physical Information
          _buildSimpleTile(
            icon: Icons.monitor_weight_outlined,
            title: 'Physical Information',
            value:
                '${_userData?.weight?.toStringAsFixed(1) ?? '50.0'} kg, ${_userData?.height?.toStringAsFixed(0) ?? '170'} cm',
          ),
          // Hydration Score
          // _buildSimpleTile(
          //   icon: Icons.show_chart,
          //   title: 'Hydration Score',
          //   value: 'Not set',
          // ),
          // Change Password
          _buildSimpleTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage()),
              );
            },
            showArrow: true,
          ),
        ],
      ),
    );
  }

  // Permissions Section
  Widget _buildPermissionsSection() {
    return Container(
      decoration: BoxDecoration(
        //color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSimpleTile(
            icon: Icons.notifications_none_outlined,
            title: 'Notifications',
            subtitle: 'Enable hydration reminders',
            isSwitch: true,
            switchValue: _notificationPermissionGranted,
            onSwitchChanged: () =>
                handlePermissionToggle(Permission.notification, "Notification"),
          ),
          //_buildDivider(),
          _buildSimpleTile(
            icon: Icons.location_on_outlined,
            title: 'Location',
            subtitle: 'Required to obtain weather',
            isSwitch: true,
            switchValue: _locationPermissionGranted,
            onSwitchChanged: () =>
                handlePermissionToggle(Permission.location, "Location"),
          ),
          //_buildDivider(),
          _buildSimpleTile(
            icon: Icons.directions_run_outlined,
            title: 'Physical Activity',
            subtitle: 'Required for Step count',
            isSwitch: true,
            switchValue: _activityPermissionGranted,
            onSwitchChanged: () => handlePermissionToggle(
                Permission.activityRecognition, "Physical Activity"),
          ),
          //_buildDivider(),
          _buildSimpleTile(
            icon: Icons.bluetooth_outlined,
            title: 'Bluetooth',
            subtitle: 'Required for bottle connection',
            isSwitch: true,
            switchValue: _bluetoothPermissionGranted,
            onSwitchChanged: () =>
                handlePermissionToggle(Permission.bluetooth, "Bluetooth"),
          ),
        ],
      ),
    );
  }

  // Support Section
  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        //color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSimpleTile(
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () {
              // Implement navigation to About Us screen
            },
            showArrow: true,
          ),
          //_buildDivider(),
          _buildSimpleTile(
            icon: Icons.phone_outlined,
            title: 'Contact Us',
            onTap: () {
              // Implement navigation to Contact Us screen
            },
            showArrow: true,
          ),
        ],
      ),
    );
  }

  // Logout Section
  Widget _buildLogoutSection() {
    return Container(
      decoration: BoxDecoration(
        //color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildSimpleTile(
        icon: Icons.logout,
        title: 'Logout',
        textColor: Colors.red,
        iconColor: Colors.red,
        onTap: () async {
          bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E2A3A),
              title: Text('Confirm Logout',
                  style: GoogleFonts.inter(color: Colors.white)),
              content: Text('Are you sure you want to logout?',
                  style: GoogleFonts.inter(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(color: Colors.blue)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Logout',
                      style: GoogleFonts.inter(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirm) {
            try {
              await _auth.signOut();
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await _notificationService.cancelAllNotifications();

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
                    content: Text("Logout failed: ${e.toString()}",
                        style: GoogleFonts.inter()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        showArrow: true,
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSimpleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? value,
    VoidCallback? onTap,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
    bool showArrow = false,
    bool isSwitch = false,
    bool switchValue = false,
    VoidCallback? onSwitchChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null)
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              if (isSwitch)
                Switch(
                  value: switchValue,
                  onChanged: (_) => onSwitchChanged?.call(),
                  activeColor: Colors.teal,
                  inactiveThumbColor: Colors.grey.shade600,
                  inactiveTrackColor: Colors.grey.shade800,
                ),
              if (showArrow)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Future<void> _scheduleHydrationNotifications() async {
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
          backgroundColor: Colors.teal,
        ),
      );
    }
  }
}
