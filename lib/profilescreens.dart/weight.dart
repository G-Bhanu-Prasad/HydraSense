import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'height.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_2/models/user_profile.dart';

class WeightSelectionScreen extends StatefulWidget {
  final UserData userData;

  const WeightSelectionScreen({super.key, required this.userData});

  @override
  WeightSelectionScreenState createState() => WeightSelectionScreenState();
}

class WeightSelectionScreenState extends State<WeightSelectionScreen> {
  double _selectedWeight = 50.0;
  bool _isKg = true; // true for Kg, false for Lb

  void _onUnitToggle(bool isKg) {
    setState(() {
      if (_isKg != isKg) {
        // Convert weight only when toggling
        if (isKg) {
          _selectedWeight = (_selectedWeight / 2.205).clamp(30, 200);
        } else {
          _selectedWeight = (_selectedWeight * 2.205).clamp(30, 440);
        }
        _isKg = isKg;
      }
    });
  }

  void _onNextPressed() {
    widget.userData.weight = _selectedWeight;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HeightSelectorScreen(userData: widget.userData),
      ),
    );
  }

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
              // Progress indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index < 3 ? Colors.blue : Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2737).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "What's your current weight?",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            "This will help us determine your goal, and monitor your progress over time.",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
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
                                icon: const Icon(Icons.remove,
                                    size: 20, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _selectedWeight = (_selectedWeight - 1)
                                        .clamp(30, _isKg ? 200 : 440);
                                  });
                                },
                              ),
                              Column(
                                children: [
                                  Text(
                                    _isKg
                                        ? _selectedWeight.toStringAsFixed(1)
                                        : (_selectedWeight * 2.205)
                                            .toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ToggleButtons(
                                    isSelected: [_isKg, !_isKg],
                                    onPressed: (index) {
                                      _onUnitToggle(index == 0);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    fillColor: Colors.blue[900],
                                    selectedColor: Colors.white,
                                    color: Colors.white70,
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text("Kg"),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text("Lb"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.add,
                                    size: 20, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _selectedWeight = (_selectedWeight + 1)
                                        .clamp(30, _isKg ? 200 : 440);
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
                      onPressed: _onNextPressed,
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
}
