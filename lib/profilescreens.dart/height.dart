import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/home_screen.dart';

class HeightSelectorScreen extends StatefulWidget {
  @override
  _HeightSelectorScreenState createState() => _HeightSelectorScreenState();
}

class _HeightSelectorScreenState extends State<HeightSelectorScreen> {
  bool isMetric = false; // Toggle between Ft/In and Cm
  double heightInCm = 170; // Default height in cm

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index < 4 ? Colors.black : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 50),
          const Text(
            "How tall are you?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Your height will help us calculate important body stats to help you reach your goals faster.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, size: 36),
                onPressed: () {
                  setState(() {
                    if (isMetric) {
                      heightInCm = (heightInCm - 1).clamp(100, 250).toDouble();
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
                        ? '${heightInCm.toStringAsFixed(1)} cm'
                        : _convertToFeetAndInches(heightInCm),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
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
                    fillColor: Colors.black,
                    selectedColor: Colors.white,
                    color: Colors.black,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Ft/In"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Cm"),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right, size: 36),
                onPressed: () {
                  setState(() {
                    if (isMetric) {
                      heightInCm = (heightInCm + 1).clamp(100, 250).toDouble();
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
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Navigate back
                  },
                  child: const Text("BACK"),
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
                            builder: (context) => const ProfileDisplayScreen()),
                      );
                    }
                  },
                  child: const Text("NEXT"),
                ),
              ],
            ),
          ),
        ],
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
