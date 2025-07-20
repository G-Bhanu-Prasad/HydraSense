import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/home_screen.dart';
import 'package:flutter_application_2/notification_service.dart';
import 'package:flutter_application_2/profilescreens.dart/login.dart';
import 'package:flutter_application_2/profilescreens.dart/name.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_application_2/foreground_task_handler.dart';
import 'package:flutter_application_2/distanceprovider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

Future<void> requestBluetoothPermissions() async {
  if (Platform.isAndroid) {
    if (!await Permission.bluetoothScan.isGranted) {
      await Permission.bluetoothScan.request();
    }

    if (!await Permission.bluetoothConnect.isGranted) {
      await Permission.bluetoothConnect.request();
    }

    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterForegroundTask.initCommunicationPort();
  tz.initializeTimeZones();
  await NotificationService().initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true;

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'hydrasense_channel',
      channelName: 'HydraSense Background BLE',
      channelDescription: 'Keeps BLE connected in background',
    ),
    iosNotificationOptions: IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      allowWakeLock: true,
      autoRunOnBoot: true,
    ),
  );

  FlutterForegroundTask.startService(
    notificationTitle: 'HydraSense Active',
    notificationText: 'Monitoring your smart bottle...',
    callback: startCallback,
  );

  await requestBluetoothPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DistanceProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
      ],
      child: HydraSense(isFirstTimeUser: isFirstTimeUser),
    ),
  );
}

class HydraSense extends StatelessWidget {
  final bool isFirstTimeUser;

  const HydraSense({super.key, required this.isFirstTimeUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydraSense',
      debugShowCheckedModeBanner: false,
      home: AuthGate(isFirstTimeUser: isFirstTimeUser),
    );
  }
}

/// ✅ AuthGate decides where to navigate based on Firebase login & first-time check
class AuthGate extends StatelessWidget {
  final bool isFirstTimeUser;

  const AuthGate({super.key, required this.isFirstTimeUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E21),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // ✅ User is signed in
          return const ProfileDisplayScreen();
        }

        if (isFirstTimeUser) {
          // 🆕 First-time user onboarding
          return const ProfileScreen();
        }

        // 🔒 Not signed in
        return const LoginPage();
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: Text(
          'HydraSense',
          style: GoogleFonts.pacifico(
            fontSize: 30,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("lib/images/wel.png"),
              const SizedBox(height: 40),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    const TextSpan(text: 'A sip today, a spark in mind, stay '),
                    TextSpan(
                      text: 'hydrated',
                      style: const TextStyle(color: Colors.blue),
                    ),
                    const TextSpan(text: ', stay aligned'),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Let’s make every drop count! 💧',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 80),
              buildGradientButton(
                context,
                label: 'Get Started',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NameInputScreen()),
                  );
                },
              ),
              const SizedBox(height: 15),
              buildGradientButton(
                context,
                label: 'Sign in',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGradientButton(BuildContext context,
      {required String label, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 10, 33, 210).withOpacity(0.3),
            Colors.cyan.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
