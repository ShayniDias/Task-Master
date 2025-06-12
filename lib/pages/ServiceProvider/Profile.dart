import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _email = "";
  String _userType = "";
  String _profileImageUrl = "";
  String? _selectedUserType;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final DatabaseEvent event = await _database.child('users/${user.uid}').once();
    final DataSnapshot snapshot = event.snapshot;
    final Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;

    if (userData != null) {
      setState(() {
        _email = userData['email'] ?? "";
        _nameController.text = userData['name'] ?? "";
        _userType = userData['userType'] ?? "";
        _profileImageUrl = userData['profileImage'] ?? "";
        _selectedUserType = _userType;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }
//save data in database
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      String imageUrl = _profileImageUrl;
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      String? token = await user.getIdToken(); // Get Firebase token

      await _database.child('users/${user.uid}').update({
        'name': _nameController.text,
        'userType': _selectedUserType,
        'profileImage': imageUrl,
        'authToken': token, // Store token in Firebase
      });

      setState(() {
        _profileImageUrl = imageUrl;
        _userType = _selectedUserType!;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.06),
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : _profileImageUrl.isNotEmpty
                          ? NetworkImage(_profileImageUrl)
                          : const AssetImage('assets/default_profile.png'),
                      backgroundColor: Colors.white10,
                    ),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ],
                ),
              ).animate().scaleXY(delay: const Duration(milliseconds: 300)),

              SizedBox(height: screenSize.height * 0.04),

              // Name Field
              TextField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: _inputDecoration("Name", Icons.person),
              ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

              SizedBox(height: screenSize.height * 0.03),

              // Email (Non-editable)
              TextField(
                controller: TextEditingController(text: _email),
                enabled: false,
                style: GoogleFonts.poppins(color: Colors.white70),
                decoration: _inputDecoration("Email", Icons.email, isDisabled: true),
              ).animate().fadeIn(delay: const Duration(milliseconds: 500)),

              SizedBox(height: screenSize.height * 0.03),

              // User Type Selector
              _buildUserTypeSelector(),

              SizedBox(height: screenSize.height * 0.04),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Save Changes",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("User Type", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        DropdownButtonFormField<String>(
          value: _selectedUserType,
          dropdownColor: const Color(0xFF1E1B4B),
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: _inputDecoration("", Icons.category),
          items: const [
            DropdownMenuItem(value: "serviceProvider", child: Text("Service Provider")),
          ],
          onChanged: (value) => setState(() => _selectedUserType = value),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {bool isDisabled = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      filled: true,
      fillColor: Colors.white10,
      enabled: !isDisabled,
    );
  }
}
