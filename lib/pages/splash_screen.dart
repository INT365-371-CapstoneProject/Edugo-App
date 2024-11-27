import 'dart:async';
import 'package:edugo/pages/provider_management.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      // Navigate to HomePage with dissolve transition
      Navigator.of(context).push(_createDissolveRoute());
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  // Create a custom route with dissolve animation
  Route _createDissolveRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const ProviderManagement(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeIn;

        var tween = Tween<double>(begin: begin, end: end)
            .chain(CurveTween(curve: curve));
        var opacityAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: opacityAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
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
