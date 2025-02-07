import 'package:flutter/material.dart';
import 'package:flutter_application_2/profilescreens.dart/weight.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? _selectedGender;

  void _onGenderSelected(String gender) {
    setState(() {
      _selectedGender = gender;
    });
  }

  void _onNextPressed() async {
    if (_selectedGender != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('gender', _selectedGender!);
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => WeightSelectionScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Gender')),
      );
    }
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
                  color: index < 2 ? Colors.black : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 50),
          const Text(
            "What's your Gender?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Gender affects your body’s water requirements. By selecting your gender, we can tailor your hydration target to keep you healthy and feeling your best.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GenderCard(
                icon: Icons.male,
                label: "Male",
                isSelected: _selectedGender == "Male",
                onTap: () => _onGenderSelected("Male"),
              ),
              const SizedBox(width: 16),
              _GenderCard(
                icon: Icons.female,
                label: "Female",
                isSelected: _selectedGender == "Female",
                onTap: () => _onGenderSelected("Female"),
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
                    Navigator.pop(context); // Go back to the previous screen
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

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.blue, width: 2)
                : Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 48, color: isSelected ? Colors.blue : Colors.black),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
