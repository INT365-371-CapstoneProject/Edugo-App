import 'package:edugo/api/firebase_api.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/firebase_options.dart';
import 'package:edugo/pages/intro.dart';
import 'package:edugo/pages/splash_screen.dart';
import 'package:edugo/features/subject/screens/subject_manage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotification();

  runApp(SplashScreenApp());
}

class SplashScreenApp extends StatelessWidget {
  const SplashScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashScreen(),
    );
  }
}
