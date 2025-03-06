import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HeightSelectorScreen extends StatefulWidget {
  const HeightSelectorScreen({super.key});

  @override
  HeightSelectorScreenState createState() => HeightSelectorScreenState();
}

class HeightSelectorScreenState extends State<HeightSelectorScreen> {
  bool isMetric = false; // Toggle between Ft/In and Cm
  double heightInCm = 170; // Default height in cm

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                'HydraSense',
                style: GoogleFonts.pacifico(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index < 4 ? Colors.blue : Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2737).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "How tall are you?",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            "Your height will help us calculate important body stats to help you reach your goals faster.",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_left,
                                    size: 20, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    if (isMetric) {
                                      heightInCm = (heightInCm - 1)
                                          .clamp(100, 250)
                                          .toDouble();
                                    } else {
                                      double inches = heightInCm / 2.54;
                                      inches = (inches - 1).clamp(39, 98);
                                      heightInCm = inches * 2.54;
                                    }
                                  });
                                },
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isMetric
                                        ? '${heightInCm.toStringAsFixed(1)}'
                                        : _convertToFeetAndInches(heightInCm),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ToggleButtons(
                                    isSelected: [!isMetric, isMetric],
                                    onPressed: (index) {
                                      setState(() {
                                        if (index == 1 && !isMetric) {
                                          // Convert Ft/In to Cm
                                          isMetric = true;
                                        } else if (index == 0 && isMetric) {
                                          // Convert Cm to Ft/In
                                          isMetric = false;
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    fillColor: Colors.blue[900],
                                    selectedColor: Colors.white,
                                    color: Colors.white70,
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text("Ft/In"),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text("Cm"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_right,
                                    size: 20, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    if (isMetric) {
                                      heightInCm = (heightInCm + 1)
                                          .clamp(100, 250)
                                          .toDouble();
                                    } else {
                                      double inches = heightInCm / 2.54;
                                      inches = (inches + 1).clamp(39, 98);
                                      heightInCm = inches * 2.54;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Navigate back
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("BACK",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        // Saving height in both formats
                        await prefs.setDouble('heightInCm', heightInCm);
                        await prefs.setString('heightInFtInches',
                            _convertToFeetAndInches(heightInCm));
                        // Save height
                        await prefs.setBool('isFirstTimeUser', false);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileDisplayScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("NEXT",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _convertToFeetAndInches(double cm) {
    double inches = cm / 2.54;
    int feet = inches ~/ 12;
    int remainingInches = (inches % 12).round();
    return "$feet' $remainingInches\"";
  }
}
