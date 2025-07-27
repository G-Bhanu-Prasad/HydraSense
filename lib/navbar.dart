import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'bottle.dart';
import 'analysis.dart';
import 'profile.dart';
import 'connected.dart';
import 'package:provider/provider.dart';
import 'distanceprovider.dart';

class BottomNavBar extends StatefulWidget {
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
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  bool _isAddWaterPressed = false;

  void _handleAddWater() async {
    if (_isAddWaterPressed) return; // Prevent multiple rapid taps

    setState(() {
      _isAddWaterPressed = true;
    });

    if (widget.addWater != null) {
      widget.addWater!();
    }

    // Allow pressing again after a short delay (e.g., 1 second)
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isAddWaterPressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0A0E21),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.blueGrey.shade400,
      currentIndex: widget.currentIndex,
      onTap: (index) {
        if (index == widget.currentIndex) return;

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProfileDisplayScreen()),
            );
            break;
          case 1:
            final isConnected =
                Provider.of<ConnectionProvider>(context, listen: false)
                    .isConnected;

            if (isConnected) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConnectedBottleScreen(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BottlePage()),
              );
            }
            break;

          case 2:
            _handleAddWater();
            break;
          case 3:
            if (widget.dailyIntakes != null &&
                widget.dailyIntakes!.isNotEmpty) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalysisPage(
                    dailyIntakes: widget.dailyIntakes!,
                  ),
                ),
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
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
