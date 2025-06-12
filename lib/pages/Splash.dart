import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Authentication.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _navigateToRegister();
  }

  _navigateToRegister() async {
    await Future.delayed(const Duration(seconds: 7));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Authentication()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple, Colors.blueAccent],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Image with Shadow
                SlideTransition(
                  position: _slideAnimation,
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Animated Text with Google Fonts Poppins
                AnimatedTextKit(
                  animatedTexts: [
                    ColorizeAnimatedText(
                      'Task Master',
                      textStyle: GoogleFonts.poppins(
                        fontSize: 40.0,
                        fontWeight: FontWeight.bold,
                      ),
                      colors: [
                        Colors.white,
                        Colors.blue,
                        Colors.yellow,
                        Colors.red,
                      ],
                      speed: const Duration(milliseconds: 400),
                    ),
                  ],
                  isRepeatingAnimation: true,
                  totalRepeatCount: 3,
                ),
                const SizedBox(height: 10),
                // Subtitle with Google Fonts Poppins
                Text(
                  "Unlocking Your Dream Job, One Click at a Time!",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 30),
                // Lottie Loading Animation
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/json/l.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                // Developed By Section
                SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    "Developed by KMS Dias - 10898446",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
