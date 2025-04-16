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

// สร้าง GlobalKey สำหรับ NavigatorState
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotification();

  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('is_first_time') ?? true;
  // สร้าง AuthService instance พร้อม navigatorKey
  final authService = AuthService(navigatorKey: navigatorKey);
  bool isValid = await authService.validateToken();

  runApp(MyApp(
    isFirstTime: isFirstTime,
    isLoggedIn: isValid,
    authService: authService, // ส่ง authService ไปให้ MyApp
  ));
}

class MyApp extends StatefulWidget {
  final bool isFirstTime;
  final bool isLoggedIn;
  final AuthService authService; // รับ AuthService instance

  const MyApp({
    super.key,
    required this.isFirstTime,
    required this.isLoggedIn,
    required this.authService, // เพิ่ม parameter นี้
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

// เพิ่ม State class และ implement WidgetsBindingObserver
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ลงทะเบียน observer
    // ทำการ check ครั้งแรกตอนเปิดแอป ถ้า login อยู่แล้ว
    if (widget.isLoggedIn) {
      widget.authService.checkSessionValidity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ยกเลิก observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ตรวจสอบเมื่อแอปกลับมาทำงาน (resumed) และผู้ใช้ login อยู่
    if (state == AppLifecycleState.resumed && widget.isLoggedIn) {
      print("App resumed. Checking session validity...");
      widget.authService.checkSessionValidity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // กำหนด navigatorKey ให้ MaterialApp
      debugShowCheckedModeBanner: false,
      title: 'Edugo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: widget.isFirstTime
          ? const IntroScreen() // แก้ไขจาก IntroPage เป็น IntroScreen
          : widget.isLoggedIn
              ? const HomeScreenApp() // เปลี่ยนจาก SplashScreen ไป HomeScreenApp โดยตรงหลัง login
              : const WelcomeUserPage(),
    );
  }
}
