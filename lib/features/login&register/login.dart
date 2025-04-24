import 'dart:convert';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/features/login&register/forgetPassword.dart';
import 'package:edugo/features/question/screens/question.dart';
import 'package:edugo/pages/welcome_user_page.dart';
import 'package:edugo/shared/utils/customBackButton.dart';
import 'package:edugo/shared/utils/loading.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:edugo/features/login&register/register.dart';
import 'package:edugo/config/api_config.dart';
import 'package:flutter_svg/svg.dart';

import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordFocused = false;
  bool _isEmailFocused = false;
  final AuthService _authService =
      AuthService(navigatorKey: navigatorKey); // เพิ่ม navigatorKey

  bool _emailError = false;
  bool _passwordError = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
  }

  void _validateAndLogin() {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
    });

    if (!_emailError && !_passwordError) {
      loginUser();
    }
  }

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
    });

    _showCustomLoadingDialog(context);

    try {
      // ตรวจสอบว่าเป็น email หรือ username
      final input = _emailController.text.trim();
      final Map<String, dynamic> requestBody = {
        'email': input.contains('@') ? input : '',
        'username': !input.contains('@') ? input : '',
        'password': _passwordController.text.trim(),
        'remember_me': true
      };

      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String token = data['token'];

        await _authService.saveToken(token);
        await addFCMToken();

        if (mounted) {
          // เรียกฟังก์ชันตรวจสอบก่อนแสดง Success Dialog
          await _performPostLoginChecksAndShowSuccess();
        }
      } else if (response.statusCode == 502) {
        if (mounted) {
          _showErrorDialog("Login Failed", "Server Error");
        }
      } else {
        if (mounted) {
          _showErrorDialog(
              "Login Failed", "Invalid email/username\nor password.");
        }
      }
    } catch (e) {
      print('Error during login: $e');
      if (mounted) {
        // ตรวจสอบว่า Loading Dialog ยังเปิดอยู่หรือไม่ก่อนปิด
        if (_isLoading) {
          Navigator.pop(context); // ปิด Loading Dialog กรณีเกิด Exception
        }
        _showErrorDialog(
            "Connection Error", "Please check your internet connection.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> addFCMToken() async {
    final url = Uri.parse(ApiConfig.fcmUrl);

    String? token = await _authService.getToken();

    // Create headers map
    Map<String, String> headers = {'Content-Type': 'application/json'};

    // Add Authorization header if token is available
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final firebaseMessaging = FirebaseMessaging.instance;

    final fCMToken = await firebaseMessaging.getToken();

    try {
      final response = await http.post(
        url,
        headers: headers, // Use the headers with the token
        body: json.encode({"fcm_token": fCMToken}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
      } else {
        print(response);
      }
    } catch (e) {
      print(e);
    }
  }

  void _showCustomLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: SizedBox(
            width: 300, // ปรับขนาดให้เหมาะสมกับเนื้อหา
            height: 360,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GradientFadeSpinner(),
                  const SizedBox(height: 24),
                  Text(
                    "Please wait...",
                    style: TextStyleService.getDmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We're logging you in",
                    style: TextStyleService.getDmSans(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<http.Response?> getAnswer() async {
    final url = Uri.parse(ApiConfig.answerUrl);
    String? token = await _authService.getToken(); // ใช้ _authService ที่มีอยู่

    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response; // ส่ง response กลับไปให้ _showSuccessDialog
      }
    } catch (e) {
      print("Error fetching answer: $e");
    }
    return null; // ถ้า error ให้ return null
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: SizedBox(
            width: 300,
            height: 360,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/failmark.png',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Try Again",
                      style: TextStyleService.getDmSans(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Dialog สำหรับแสดงข้อผิดพลาดเฉพาะหลัง Login (เช่น Suspended, Not Verified)
  void _showLoginErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // ห้ามปิดด้วยการแตะนอกพื้นที่
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 300,
            height: 360,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image.asset(
                  //   'assets/images/warning_icon.png', // เปลี่ยนเป็นไอคอนที่ใช้ได้ เช่น warning, alert
                  //   height: 100,
                  //   width: 100,
                  // ),
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 120,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Try Again",
                      style: TextStyleService.getDmSans(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ฟังก์ชันดึงข้อมูลโปรไฟล์
  Future<Map<String, dynamic>?> fetchProfileData() async {
    final url = Uri.parse(ApiConfig.profileUrl);
    String? token = await _authService.getToken(); // ใช้ _authService ที่มีอยู่

    if (token == null) {
      print("Token not found for fetching profile.");
      return null;
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('profile') && data['profile'] is Map) {
          return data['profile'] as Map<String, dynamic>; // คืนค่าข้อมูลโปรไฟล์
        } else {
          print("Profile data not found or invalid format in response.");
          return null;
        }
      } else {
        print(
            "Failed to load profile data: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      return null;
    }
  }

  // ฟังก์ชันจัดการการ Logout เมื่อเกิดข้อผิดพลาดหลัง Login
  Future<void> _handleLogoutOnError() async {
    try {
      await _authService.removeToken(); // ใช้ _authService ที่มีอยู่
      await _authService.removeFCMToken();
    } catch (e) {
      print("Error during logout on error: $e");
    }
  }

  // ฟังก์ชันตรวจสอบหลัง Login และแสดง Success Dialog หากผ่าน
  Future<void> _performPostLoginChecksAndShowSuccess() async {
    final profileData = await fetchProfileData();

    if (!mounted) return;

    if (profileData == null) {
      await _handleLogoutOnError();
      _showLoginErrorDialog(
          "Error", "Failed to retrieve profile information. Please log out.");
      return;
    }

    // 1. ตรวจสอบ Status
    final status = profileData['status'];
    if (status == 'Suspended') {
      await _handleLogoutOnError();
      _showLoginErrorDialog("Account Suspended",
          "Your account is currently suspended. Please contact support.");
      return;
    }

    // 2. ตรวจสอบ Role และ Verify (สำหรับ Provider)
    final role = profileData['role'];
    if (role == 'provider') {
      final verify = profileData['verify'];
      if (verify == 'No') {
        await _handleLogoutOnError();
        _showLoginErrorDialog(
          "Verification Required",
          "Your provider account has not been verified. Please contact support.",
        );
        return; // ออกจากการทำงานหลัง logout
      } else if (verify == 'Waiting') {
        print("Provider verification is 'Waiting'. Logging out.");
        await _handleLogoutOnError();
        _showLoginErrorDialog(
          "Verification Pending",
          "Your provider account is awaiting verification. Please wait for approval.",
        );
        return; // ออกจากการทำงานหลัง logout
      }
      // ถ้า verify เป็น 'Yes' ก็ผ่าน
    }

    // --- ถ้าผ่านการตรวจสอบ Profile ---
    // 3. เรียก getAnswer() เพื่อตัดสินใจหน้าถัดไป
    final response = await getAnswer();

    if (!mounted) return;

    Widget? pageToNavigate; // ตัวแปรเก็บหน้าที่ต้องการไป

    if (response != null) {
      try {
        final data = json.decode(response.body);
        if (data.containsKey("categories") &&
            data.containsKey("countries") &&
            data.containsKey("education_level")) {
          if (data["categories"].isEmpty &&
              data["countries"].isEmpty &&
              data["education_level"] == null) {
            pageToNavigate = const Question(); // กำหนดหน้า Question
          } else {
            pageToNavigate = const HomeScreenApp(); // กำหนดหน้า HomeScreen
          }
        } else {
          print("Unexpected data structure from getAnswer API.");
          pageToNavigate = const HomeScreenApp(); // Default ไป HomeScreen
        }
      } catch (e) {
        print("Error decoding answer response: $e");
        await _handleLogoutOnError();
        _showLoginErrorDialog("Error",
            "Failed to process navigation data. Please log out and try again.");
        return; // ออกจากการทำงานถ้า decode ไม่ได้
      }
    } else {
      print("Failed to get answer data for navigation.");
      // อาจจะ logout หรือไปหน้า default ขึ้นอยู่กับนโยบาย
      pageToNavigate = const HomeScreenApp(); // Default ไป HomeScreen
      // หรือถ้าข้อมูล answer จำเป็นมาก:
      // await _handleLogoutOnError();
      // _showLoginErrorDialog("Error", "Could not retrieve necessary data. Please log out and try again.");
      // return;
    }

    // --- ถ้าผ่านการตรวจสอบทั้งหมด และได้หน้าที่ต้องการไป ---
    if (pageToNavigate != null) {
      // แสดง Success Dialog และนำทางหลังจาก Delay
      _showSuccessDialogAndNavigate(pageToNavigate);
    }
    // กรณี pageToNavigate เป็น null (ซึ่งไม่ควรเกิดจาก logic ปัจจุบัน แต่เป็นการป้องกัน)
    else {
      print("Error: pageToNavigate is null after checks.");
      await _handleLogoutOnError();
      _showLoginErrorDialog("Internal Error",
          "An unexpected error occurred during login. Please try again.");
    }
  }

  void _showSuccessDialogAndNavigate(Widget page) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 300,
            height: 360,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/success_check.png",
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Login Successful",
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Welcome to Edugo!",
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // ปิด dialog
        _navigateToPage(page); // นำทางไปหน้าใหม่
      }
    });
  }

  void _navigateToPage(Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false, // เพิ่มพารามิเตอร์นี้เพื่อลบทุก route ก่อนหน้า
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 111),
                // Logo
                Center(
                  child: SizedBox(
                    width: 175,
                    height: 37.656,
                    child: Image.asset(
                      "assets/images/logoColor.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // detail
                FractionallySizedBox(
                  widthFactor: 1, // ให้เต็มความกว้างของหน้าจอ
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 23.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Login",
                              style: TextStyleService.getDmSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                height: 1.33333,
                              ),
                            ),
                            SizedBox(height: 6.49),
                            Text(
                              'Login to continue using the app',
                              textAlign: TextAlign.left,
                              style: TextStyleService.getDmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w200,
                                color: Color(0xFF465468),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 63.51),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Email / Username",
                              style: TextStyleService.getDmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                color: Color(0xFF000000),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFECF0F6),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: _isEmailFocused
                                    ? [
                                        BoxShadow(
                                          color: _emailError
                                              ? Color.fromRGBO(
                                                  237, 75, 158, 0.15)
                                              : Color.fromRGBO(
                                                  108, 99, 255, 0.15),
                                          blurRadius: 0,
                                          spreadRadius: 6,
                                          offset: Offset(0, 0),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                style: TextStyleService.getDmSans(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      "Enter your email address or username",
                                  hintStyle: TextStyleService.getDmSans(
                                    color: Colors.black.withOpacity(0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFECF0F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9.51),
                                    borderSide: _emailError
                                        ? const BorderSide(
                                            color: Colors.red, width: 2.0)
                                        : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9.51),
                                    borderSide: _emailError
                                        ? const BorderSide(
                                            color: Colors.red, width: 2.0)
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9.51),
                                    borderSide: _emailError
                                        ? const BorderSide(
                                            color: Colors.red, width: 2.0)
                                        : const BorderSide(
                                            color: Color(0xFFC0CDFF)),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_emailError)
                              Text(
                                "Please enter your email or username",
                                style: TextStyleService.getDmSans(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            SizedBox(height: 16),

                            // Password Field
                            Text(
                              "Password",
                              style: TextStyleService.getDmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                color: Color(0xFF000000),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFECF0F6),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: _isPasswordFocused
                                    ? [
                                        BoxShadow(
                                          color: _passwordError
                                              ? Color.fromRGBO(
                                                  237, 75, 158, 0.15)
                                              : Color.fromRGBO(
                                                  108, 99, 255, 0.15),
                                          blurRadius: 0,
                                          spreadRadius: 6,
                                          offset: Offset(0, 0),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: !_isPasswordVisible,
                                style: TextStyleService.getDmSans(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter your password",
                                  hintStyle: TextStyleService.getDmSans(
                                    color: Colors.black.withOpacity(0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9.51),
                                    borderSide: _passwordError
                                        ? const BorderSide(
                                            color: Colors.red, width: 2.0)
                                        : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9.51),
                                    borderSide: _passwordError
                                        ? const BorderSide(
                                            color: Colors.red, width: 2.0)
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9.51),
                                    borderSide: _passwordError
                                        ? const BorderSide(
                                            color: Colors.red, width: 2.0)
                                        : const BorderSide(
                                            color: Color(0xFFC0CDFF)),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Color(0xFFCBD5E0),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_passwordError)
                              Text(
                                "Please enter your password",
                                style: TextStyleService.getDmSans(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const ForgetPassword(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = 0.0;
                                        const end = 1.0;
                                        const curve = Curves.easeOut;

                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        return FadeTransition(
                                          opacity: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                      transitionDuration:
                                          const Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyleService.getDmSans(
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF64738B),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 111),

                      // Login Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              _validateAndLogin();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF355FFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Login",
                              style: TextStyleService.getDmSans(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 27),
                      Center(
                        child: SvgPicture.asset(
                          "assets/images/line_login.svg",
                          width: 320,
                        ),
                      ),

                      // Register Section แบ่งเป็น 2 ส่วน
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            // User Register
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyleService.getDmSans(
                                    color: Color(0xFF64738B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const Register(isUser: true),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Register",
                                    style: TextStyleService.getDmSans(
                                      color: Color(0xFF355FFF),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Provider Register
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Want to become a provider? ",
                                  style: TextStyleService.getDmSans(
                                    color: Color(0xFF64738B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const Register(isProvider: true),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Register", // Changed from "Register as Provider"
                                    style: TextStyleService.getDmSans(
                                      color: Color(0xFF355FFF),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CustomBackButton(pageToNavigate: const WelcomeUserPage()),
        ],
      ),
    );
  }
}
