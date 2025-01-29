import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_2/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ProfileSetupScreenState createState() => ProfileSetupScreenState();
}

class ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController goalController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String age = '';
  String selectedGender = 'Male'; // Default gender selection
  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    fetchExistingUserDetails();
  }

  void fetchExistingUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('userName') ?? '';
      String dobString = prefs.getString('userDOB') ?? '';
      goalController.text = prefs.getString('defaultGoal') ?? '2000';
      selectedGender = prefs.getString('userGender') ?? 'Male';
      if (dobString.isNotEmpty) {
        selectedDate = DateFormat('yyyy-MM-dd').parse(dobString);
        dobController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
        calculateAge(selectedDate);
      }
    });
  }

  void calculateAge(DateTime dob) {
    DateTime now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    setState(() {
      this.age = age.toString();
    });
  }

  void saveProfile(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', nameController.text);
    await prefs.setString('userDOB', dobController.text);
    await prefs.setString('defaultGoal', goalController.text);
    await prefs.setString('userGender', selectedGender); // Save gender
    await prefs.setBool('isFirstTimeUser', false);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileDisplayScreen()),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.lightBlue[50],
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 9, 47, 103),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 9, 47, 103),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
        calculateAge(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade100,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.blueGrey.shade100,
        title: Text(
          'Profile Setup',
          style: TextStyle(
              color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8.0),
              Text(
                "Empower Your Day with Smart Hydration Setup",
                style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade800),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  SizedBox(
                    width: 325,
                    height: 80,
                    child: TextField(
                      cursorColor: Colors.blueGrey.shade800,
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        floatingLabelStyle:
                            TextStyle(color: Colors.blueGrey.shade800),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueGrey.shade600)),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueGrey.shade800)),
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.blueGrey.shade100,
                      ),
                      style: TextStyle(
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 325,
                        height: 80,
                        child: TextField(
                          controller: dobController,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            floatingLabelStyle:
                                TextStyle(color: Colors.blueGrey.shade800),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blueGrey.shade600)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blueGrey.shade800)),
                            filled: true,
                            fillColor: Colors.blueGrey.shade100,
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              //const SizedBox(height: 8.0),
              Text(
                'Age: $age',
                style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade800),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  SizedBox(
                    width: 325,
                    child: DropdownButtonFormField<String>(
                      value: selectedGender,
                      items: genderOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        floatingLabelStyle:
                            TextStyle(color: Colors.blueGrey.shade800),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueGrey.shade600)),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueGrey.shade800)),
                        filled: true,
                        fillColor: Colors.blueGrey.shade100,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedGender = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  SizedBox(
                    width: 325,
                    height: 80,
                    child: TextField(
                      controller: goalController,
                      decoration: InputDecoration(
                        labelText: 'Daily Goal (ml)',
                        floatingLabelStyle:
                            TextStyle(color: Colors.blueGrey.shade800),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueGrey.shade600)),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueGrey.shade800)),
                        filled: true,
                        fillColor: Colors.blueGrey.shade100,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 9, 47, 103),
                ),
                onPressed: () => saveProfile(context),
                child: Text('Save',
                    style: TextStyle(
                      color: Colors.blueGrey.shade100,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
