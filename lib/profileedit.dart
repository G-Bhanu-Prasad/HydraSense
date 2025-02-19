import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ProfileEditScreenState createState() => ProfileEditScreenState();
}

class ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool _isPasswordVisible = false;
  String selectedGender = 'Male'; // Default
  int selectedAge = 18; // Default

  @override
  void initState() {
    super.initState();
    loadProfileDetails();
  }

  Future<void> loadProfileDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      firstNameController.text = prefs.getString('userName') ?? 'Unknown';
      emailController.text = prefs.getString('email') ?? 'Unknown';
      selectedAge = prefs.getInt('age') ?? 18;
      heightController.text =
          prefs.getDouble('heightInCm')?.toStringAsFixed(0) ?? '170';
      weightController.text =
          prefs.getDouble('weight')?.toStringAsFixed(1) ?? '50';
      selectedGender = prefs.getString('gender') ?? 'Male';
    });
  }

  Future<void> saveProfileDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', firstNameController.text);
    await prefs.setInt('age', selectedAge);
    await prefs.setDouble(
        'heightInCm', double.tryParse(heightController.text) ?? 170);
    await prefs.setDouble(
        'weight', double.tryParse(weightController.text) ?? 50);
    await prefs.setString('gender', selectedGender);

    Navigator.pop(context, true); // Return to ProfilePage
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller,
      {String? suffixText}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.cyan.shade900.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan.shade900.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        cursorColor: Colors.cyan.shade900,
        keyboardType: TextInputType.text,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: InputBorder.none,
          suffixText: suffixText,
          suffixStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
      {required T value,
      required List<T> items,
      required void Function(T?) onChanged}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.cyan.shade900.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan.shade900.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1F32),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withOpacity(0.5)),
          items: items
              .map((T item) => DropdownMenuItem<T>(
                  value: item, child: Text(item.toString())))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Colors.white.withOpacity(0.7), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.cyanAccent, // Border color
                          width: 2, // Border thickness
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('lib/images/profile1.jpg'),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromARGB(255, 10, 33, 210)
                                  .withOpacity(0.3),
                              Colors.cyan.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Icon(Icons.edit,
                            size: 16, color: Colors.white.withOpacity(0.9)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('PERSONAL INFORMATION',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue)),
              const SizedBox(height: 10),
              _buildLabel('Full Name'),
              _buildTextField(firstNameController),
              const SizedBox(height: 10),
              _buildLabel('Change Email'),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.cyan.shade900.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.cyan.shade900.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: emailController,
                  //obscureText: !_isPasswordVisible,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.left,
                  cursorColor: Colors.cyan.shade900,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 16), // Equal space above and below
                    border: InputBorder.none,
                    // suffixIcon: IconButton(
                    //   icon: Icon(
                    //     _isPasswordVisible
                    //         ? Icons.visibility
                    //         : Icons.visibility_off,
                    //     color: Colors.white.withOpacity(0.5),
                    //   ),
                    //   onPressed: () {
                    //     setState(() {
                    //       _isPasswordVisible = !_isPasswordVisible;
                    //     });
                    //   },
                    // ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('PHYSICAL INFORMATION',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Gender'),
                        _buildDropdown(
                          value: selectedGender,
                          items: ['Male', 'Female', 'Other'],
                          onChanged: (String? newValue) => setState(
                              () => selectedGender = newValue ?? 'Male'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Age'),
                        _buildDropdown(
                          value: selectedAge,
                          items: List.generate(100, (index) => index + 1),
                          onChanged: (int? newValue) =>
                              setState(() => selectedAge = newValue ?? 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Weight'),
                        _buildTextField(weightController, suffixText: 'kg'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Height'),
                        _buildTextField(heightController, suffixText: 'cm'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 10, 33, 210).withOpacity(0.3),
                      Colors.cyan.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: saveProfileDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent, // Make background transparent
                    shadowColor: Colors.transparent, // Remove shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
