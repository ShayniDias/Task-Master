import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _forgotPasswordEmailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController(); // Added for username

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _selectedUserType;
  double _cardHeight = 440; // Increased height

  final List<Map<String, dynamic>> _userTypes = [
    {'value': 'customer', 'label': 'Customer', 'icon': FontAwesomeIcons.user},
    {'value': 'serviceProvider', 'label': 'Provider', 'icon': FontAwesomeIcons.building},
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
//redirect when user loged in
  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  Future<void> _checkUserLoggedIn() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DatabaseEvent event = await _database.child('users/${user.uid}').once();
      final DataSnapshot snapshot = event.snapshot;
      final Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;

      if (userData != null) {
        final String userType = userData['userType'];
        _redirectBasedOnUserType(userType);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            decoration: BoxDecoration(
              gradient: SweepGradient(
                center: Alignment.center,
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF4338CA),
                  const Color(0xFF1E1B4B),
                ],
                stops: const [0.1, 0.5, 0.9],
              ),
            ),
          ),

          // Blurred card content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title with animated entrance
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Join Us!',
                    style: GoogleFonts.poppins(
                      fontSize: screenSize.width * 0.08,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 500))
                      .slideY(
                      begin: -0.1,
                      end: 0,
                      curve: Curves.easeOutCubic),

                  SizedBox(height: screenSize.height * 0.04),

                  // Auth card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: screenSize.width * 0.9,
                    height: _cardHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: _buildAuthContent(screenSize),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isSubmitting)
            Container(
              color: Colors.black54,
            ),
        ],
      ),
    );
  }

  Widget _buildAuthContent(Size screenSize) {
    return Padding(
      padding: EdgeInsets.all(screenSize.width * 0.06),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Auth mode switcher
            _buildAuthSwitcher(screenSize),
            SizedBox(height: screenSize.height * 0.03),

            // Form fields
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildEmailField(),
                    SizedBox(height: screenSize.height * 0.02),
                    if (!_isLogin) ...[
                      _buildUsernameField(), // Added username field
                      SizedBox(height: screenSize.height * 0.02),
                    ],
                    _buildPasswordField(),
                    if (_isLogin) ...[
                      SizedBox(height: screenSize.height * 0.01), // Space between password field and forgot password
                      _buildForgotPasswordButton(),
                      SizedBox(height: screenSize.height * 0.02), // Space between forgot password and continue button
                    ],
                    if (!_isLogin) ...[
                      SizedBox(height: screenSize.height * 0.02),
                      _buildConfirmPasswordField(),
                      SizedBox(height: screenSize.height * 0.02),
                      _buildUserTypeSelector(),
                    ],
                    SizedBox(height: screenSize.height * 0.03),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // switching signin signup tabs
  Widget _buildAuthSwitcher(Size screenSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _AuthSwitchButton(
              label: 'Sign In',
              isActive: _isLogin,
              onTap: () => _toggleAuthMode(true),
            ),
          ),
          Expanded(
            child: _AuthSwitchButton(
              label: 'Sign Up',
              isActive: !_isLogin,
              onTap: () => _toggleAuthMode(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.email_rounded, color: Colors.white70),
        labelText: 'Email',
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.white),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder().copyWith(
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
    ).animate().scaleXY(delay: const Duration(milliseconds: 100));
  }

  Widget _buildUsernameField() { // Added username field
    return TextFormField(
      controller: _usernameController,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.person, color: Colors.white70),
        labelText: 'Username',
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.white),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder().copyWith(
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter your username' : null,
    ).animate().scaleXY(delay: const Duration(milliseconds: 150));
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        labelText: 'Password',
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.white),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder().copyWith(
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      validator: (value) =>
      value!.length < 6 ? 'Password must be at least 6 characters' : null,
    ).animate().scaleXY(delay: const Duration(milliseconds: 200));
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_reset_rounded, color: Colors.white70),
        labelText: 'Confirm Password',
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.white),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder().copyWith(
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      validator: (value) =>
      value != _passwordController.text ? 'Passwords do not match' : null,
    ).animate().scaleXY(delay: const Duration(milliseconds: 300));
  }

  Widget _buildUserTypeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _userTypes.map((type) {
        final isSelected = _selectedUserType == type['value'];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [const Color(0xFF031FEF), const Color(0xFF554AD8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white38,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _selectedUserType = type['value']),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type['icon'], size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(type['label'], style: GoogleFonts.poppins(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().scaleXY(delay: const Duration(milliseconds: 400));
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              _isLogin ? 'Continue' : 'Create Account',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showForgotPasswordDialog,
        child: Text(
          'Forgot Password?',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  InputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white38, width: 1.2),
    );
  }

  void _toggleAuthMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
      _cardHeight = isLogin ? 460 : 560; // Adjusted height for username field
      if (isLogin) _selectedUserType = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      if (_isLogin) {
        await _signIn();
      } else {
        await _signUp();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signIn() async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final User? user = userCredential.user;
      if (user != null) {
        final DatabaseEvent event = await _database.child('users/${user.uid}').once();
        final DataSnapshot snapshot = event.snapshot;
        final Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;

        if (userData != null) {
          final String userType = userData['userType'];
          _redirectBasedOnUserType(userType);
        } else {
          throw Exception('User data not found');
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to sign in: ${e.message}');
    }
  }

  Future<void> _signUp() async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final User? user = userCredential.user;
      if (user != null) {
        await _database.child('users/${user.uid}').set({
          'email': _emailController.text,
          'name': _usernameController.text, // Added username
          'userType': _selectedUserType,
        });

        _redirectBasedOnUserType(_selectedUserType!);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to sign up: ${e.message}');
    }
  }
//navigate on usertype
  void _redirectBasedOnUserType(String userType) {
    if (userType == 'customer') {
      Navigator.pushReplacementNamed(context, '/customer');
    } else if (userType == 'serviceProvider') {
      Navigator.pushReplacementNamed(context, '/serviceProvider');
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Forgot Password',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email to reset your password.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _forgotPasswordEmailController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_rounded, color: Colors.grey),
                  labelText: 'Email',
                  floatingLabelStyle: GoogleFonts.poppins(color: Colors.black),
                  border: _inputBorder(),
                  enabledBorder: _inputBorder(),
                  focusedBorder: _inputBorder().copyWith(
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _sendPasswordResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_forgotPasswordEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _forgotPasswordEmailController.text);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _AuthSwitchButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AuthSwitchButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? Colors.white24 : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

















































































































































































































































































































































































