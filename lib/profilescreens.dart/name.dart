import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gender.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedAge = 18; // Default age

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveNameAndNavigate(BuildContext context) async {
    if (_nameController.text.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text);
      await prefs.setInt('age', _selectedAge);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GenderSelectionScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                    color: index < 1 ? Colors.black : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Text(
                "Every great journey starts with a name and age. Let's set the foundation for your hydration goals!",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const Text(
              "What is your name?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select your age:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                "Your age allows us to personalize your water goal for the best results",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedAge > 1) _selectedAge--;
                    });
                  },
                  icon: const Icon(Icons.remove_circle, size: 30),
                ),
                Text(
                  '$_selectedAge',
                  style: const TextStyle(fontSize: 24),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedAge < 150) _selectedAge++;
                    });
                  },
                  icon: const Icon(Icons.add_circle, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _saveNameAndNavigate(context),
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
