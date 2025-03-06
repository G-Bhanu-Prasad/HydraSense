import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'bottle.dart';
import 'analysis.dart';
import 'profile.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function? addWater;
  final Map<String, int>? dailyIntakes;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.addWater,
    this.dailyIntakes,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0A0E21),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.blueGrey.shade400,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; // Prevent unnecessary navigation

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProfileDisplayScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BottlePage()),
            );
            break;
          case 2:
            if (addWater != null) {
              addWater!(); // Call the function if provided
            }
            break;
          case 3:
            if (dailyIntakes != null && dailyIntakes!.isNotEmpty) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => AnalysisPage(
                          dailyIntakes: dailyIntakes!,
                        )),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No data available for Analysis!'),
                ),
              );
            }
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_rounded), label: 'Bottle'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline), label: 'Add'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analysis'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
