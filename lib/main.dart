import 'package:flutter/material.dart';
import 'package:flutter_application_2/profilescreens.dart/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/profilescreens.dart/name.dart';
import 'package:flutter_application_2/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:flutter_application_2/profilescreens.dart/logo.dart';

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Check if the user is a first-time user before launching the app
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true;

  runApp(HydraSense(isFirstTimeUser: isFirstTimeUser));
}

class HydraSense extends StatelessWidget {
  final bool isFirstTimeUser;

  const HydraSense({super.key, required this.isFirstTimeUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydraSense',
      debugShowCheckedModeBanner: false,
      home: isFirstTimeUser
          ? const ProfileScreen()
          : const ProfileDisplayScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    //_markUserAsNotFirstTime();
  }

  // Future<void> _markUserAsNotFirstTime() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('isFirstTimeUser', false);
  // }

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
              // const HydraSenseLogo(
              //   size: 300,
              //   showText: true,
              // ),
              // const HydraSenseLogo(
              //   size: 180,
              //   animate: false,
              // ),

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
              Container(
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NameInputScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Sign in',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
