import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_2/profile.dart'; // Assuming ProfilePage is in profile.dart

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askPasswordThenNavigate();
    });
  }

  Future<void> _askPasswordThenNavigate() async {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2737),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.blue.shade300, size: 28),
              const SizedBox(width: 12),
              Text(
                'Verify Identity',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please enter your password to securely edit your profile.',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                cursorColor: Colors.blue,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  prefixIcon: Icon(Icons.vpn_key_outlined, color: Colors.blue.shade300),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.red.shade300.withOpacity(0.5)),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final email = user?.email;
                final password = passwordController.text.trim();

                if (email == null || password.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          user == null ? "User not logged in." : "Password cannot be empty.",
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Colors.orange.shade700,
                      ),
                    );
                  }
                  return;
                }

                try {
                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: password,
                  );
                  await user!.reauthenticateWithCredential(credential);

                  final doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  if (doc.exists && context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditFormScreen(existingData: doc.data()!),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "User data not found.",
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  String message;
                  if (e.code == 'wrong-password') {
                    message = "Incorrect password. Please try again.";
                  } else if (e.code == 'user-not-found') {
                    message = "User not found. Please check your email.";
                  } else {
                    message = "Authentication failed: ${e.message}";
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message, style: GoogleFonts.inter()),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("An unexpected error occurred: $e", style: GoogleFonts.inter()),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade400),
            const SizedBox(height: 20),
            Text(
              'Verifying identity...',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class EditFormScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;

  const EditFormScreen({super.key, required this.existingData});

  @override
  State<EditFormScreen> createState() => _EditFormScreenState();
}

class _EditFormScreenState extends State<EditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController weightController;
  late TextEditingController heightController;
  String? _selectedGender; // New state variable for gender

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.existingData['userName'] ?? '');
    ageController = TextEditingController(
        text: (widget.existingData['age'] ?? 0).toString());
    weightController = TextEditingController(
        text: (widget.existingData['weight'] ?? 0.0).toString());
    heightController = TextEditingController(
        text: (widget.existingData['height'] ?? 0.0).toString());
    _selectedGender = widget.existingData['gender'] as String?; // Initialize gender
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User not logged in.", style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'userName': nameController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 0,
        'weight': double.tryParse(weightController.text.trim()) ?? 0.0,
        'height': double.tryParse(heightController.text.trim()) ?? 0.0,
        'gender': _selectedGender, // Save the selected gender
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile updated successfully!", style: GoogleFonts.inter()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile: $e", style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.cyan.shade900.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue.shade800.withOpacity(0.7),
                  child: Icon(
                    _selectedGender == 'Male'
                        ? Icons.male // Male icon
                        : _selectedGender == 'Female'
                            ? Icons.female // Female icon
                            : Icons.person, // Default icon for 'Other' or null
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Update your personal information below.',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildField(
                "Full Name",
                nameController,
                icon: Icons.person_outline,
                validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
              ),
              _buildGenderSelectionField(), // New gender selection field
              _buildField(
                "Age",
                ageController,
                icon: Icons.cake_outlined,
                inputType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Age cannot be empty';
                  if (int.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              _buildField(
                "Weight (kg)",
                weightController,
                icon: Icons.monitor_weight_outlined,
                inputType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Weight cannot be empty';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              _buildField(
                "Height (cm)",
                heightController,
                icon: Icons.height_outlined,
                inputType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Height cannot be empty';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: Colors.blue.shade900.withOpacity(0.5),
                ),
                child: Text(
                  "Save Changes",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? inputType,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        cursorColor: Colors.blue,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.white70),
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue.shade300) : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildGenderSelectionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: GoogleFonts.inter(color: Colors.white70),
          prefixIcon: Icon(Icons.wc_outlined, color: Colors.blue.shade300),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        dropdownColor: const Color(0xFF1A2737), // Dark dropdown background
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        items: const <String>['Male', 'Female', 'Other']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: GoogleFonts.inter(color: Colors.white)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue;
          });
        },
        validator: (value) => value == null ? 'Please select your gender' : null,
      ),
    );
  }
}
