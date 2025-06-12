import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'pages/Authentication.dart';
import 'pages/Splash.dart';
import 'pages/Customer/CustomerDashboard.dart';
import 'pages/ServiceProvider/ServiceProviderDashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/customer': (context) => const CustomerDashboard(),
        '/serviceProvider': (context) => const ServiceProviderDashboard(),
        '/authentication': (context) => const Authentication(),
      },
    );
  }
}
