import 'package:edugo/api/firebase_api.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/firebase_options.dart';
import 'package:edugo/pages/intro.dart';
import 'package:edugo/pages/splash_screen.dart';
import 'package:edugo/features/subject/subject_manage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edugo/pages/welcome_user_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotification();

  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('is_first_time') ?? true;
  final authService = AuthService();
  bool isValid = await authService.validateToken();

  if (isFirstTime) {
    await prefs.setBool('is_first_time', false);
  }

  runApp(MyApp(isFirstTime: isFirstTime, isLoggedIn: isValid));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  final bool isLoggedIn;

  const MyApp({super.key, required this.isFirstTime, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edugo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: isLoggedIn
          ? const HomeScreenApp()
          : isFirstTime
              ? const IntroScreen()
              : const Login(), // Changed from WelcomeUserPage to Login
    );
  }
}
