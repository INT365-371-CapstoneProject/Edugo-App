import 'dart:async';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/pages/intro.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstTime;
  final bool isLoggedIn;

  const SplashScreen({
    super.key,
    required this.isFirstTime,
    required this.isLoggedIn,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      // ตรวจสอบว่า widget ยังอยู่ใน tree ก่อนเรียก Navigator
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                _getNextScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = 0.0;
              const end = 1.0;
              const curve = Curves.easeOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return FadeTransition(
                  opacity: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  Widget _getNextScreen() {
    if (widget.isFirstTime) {
      return const IntroScreen();
    } else if (widget.isLoggedIn) {
      return const HomeScreenApp();
    } else {
      return const Login();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3056E6),
      body: Center(
        child: Transform.scale(
          scale: 0.7,
          child: Image.asset("assets/images/logo.png"),
        ),
      ),
    );
  }
}
