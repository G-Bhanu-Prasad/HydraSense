import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'height.dart';

class WeightSelectionScreen extends StatefulWidget {
  const WeightSelectionScreen({super.key});

  @override
  _WeightSelectionScreenState createState() => _WeightSelectionScreenState();
}

class _WeightSelectionScreenState extends State<WeightSelectionScreen> {
  double _selectedWeight = 50.0;
  bool _isKg = true; // true for Kg, false for Lb

  void _onUnitToggle(bool isKg) {
    setState(() {
      _isKg = isKg;
    });
  }

  void _onNextPressed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weight', _selectedWeight);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => HeightSelectorScreen()));
    // Navigate to the next screen if needed
  }

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
                  color: index < 3 ? Colors.black : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 50),
          const Text(
            "What's your current weight?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "This will help us determine your goal, and monitor your progress over time.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          // Moving the weight selector and toggle buttons up here
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left, size: 36),
                    onPressed: () {
                      setState(() {
                        _selectedWeight =
                            (_selectedWeight - 1).clamp(30, 200).toDouble();
                      });
                    },
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isKg
                            ? _selectedWeight.toStringAsFixed(1)
                            : (_selectedWeight * 2.205).toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ToggleButtons(
                        isSelected: [_isKg, !_isKg],
                        onPressed: (index) {
                          _onUnitToggle(index == 0);
                        },
                        borderRadius: BorderRadius.circular(20),
                        fillColor: Colors.black,
                        selectedColor: Colors.white,
                        color: Colors.black,
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Kg"),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Lb"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right, size: 36),
                    onPressed: () {
                      setState(() {
                        _selectedWeight =
                            (_selectedWeight + 1).clamp(30, 200).toDouble();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const Spacer(), // Ensures the button stays at the bottom
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
                  onPressed: _onNextPressed,
                  child: const Text("NEXT"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
