import 'package:edugo/pages/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
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
