// connected_bottle_screen.dart
import 'package:flutter/material.dart';

class ConnectedBottleScreen extends StatelessWidget {
  const ConnectedBottleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Bottle Connected'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, size: 80, color: Colors.greenAccent),
            SizedBox(height: 20),
            Text(
              'Bottle is connected!',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'Battery: 85%', // TODO: Replace with dynamic value
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            // Add more info here: signal strength, distance, etc.
          ],
        ),
      ),
    );
  }
}
