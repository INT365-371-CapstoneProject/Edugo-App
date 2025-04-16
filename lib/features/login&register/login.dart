import 'dart:convert';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/features/login&register/forgetPassword.dart';
import 'package:edugo/features/question/screens/question.dart';
import 'package:edugo/pages/welcome_user_page.dart';
import 'package:edugo/shared/utils/customBackButton.dart';
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
  final AuthService _authService =
      AuthService(navigatorKey: navigatorKey); // เพิ่ม navigatorKey

  bool _emailError = false;
  bool _passwordError = false;

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

    _showLoadingDialog();

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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String token = data['token'];

        await _authService.saveToken(token);
        await addFCMToken();

        if (mounted) {
          // เรียกฟังก์ชันตรวจสอบก่อนแสดง Success Dialog
          await _performPostLoginChecksAndShowSuccess();
        }
      } else {
        if (mounted) {
          _showErrorDialog("Login Failed",
              "Invalid email/username or password. Please try again.");
        }
      }
    } catch (e) {
      print('Error during login: $e');
      if (mounted) {
        // ตรวจสอบว่า Loading Dialog ยังเปิดอยู่หรือไม่ก่อนปิด
        if (_isLoading) {
          Navigator.pop(context); // ปิด Loading Dialog กรณีเกิด Exception
        }
        _showErrorDialog("Connection Error",
            "Please check your internet connection and try again.");
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
        print("Success");
      } else {
        print(response);
      }
    } catch (e) {
      print(e);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // ป้องกันผู้ใช้ปิด Popup เอง
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(), // วงกลมโหลด
                SizedBox(height: 16),
                Text("Logging in...", style: TextStyle(fontSize: 16)),
              ],
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
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          content: Text(message, textAlign: TextAlign.center),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog สำหรับแสดงข้อผิดพลาดเฉพาะหลัง Login (เช่น Suspended, Not Verified)
  void _showLoginErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิด dialog โดยการแตะนอกพื้นที่
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.orange), // สีส้มสำหรับ Warning
          ),
          content: Text(message, textAlign: TextAlign.center),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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
      print("User logged out due to post-login check failure.");
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
      _showLoginErrorDialog("Error",
          "Failed to retrieve profile information. Please log out and try again.");
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
        print("Provider verification is 'No'. Logging out.");
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

  // แก้ไข: แสดง Success Dialog และนำทางหลังจาก Delay
  void _showSuccessDialogAndNavigate(Widget page) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            "Login Successful",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green),
          ),
          content: const Text("Welcome back!", textAlign: TextAlign.center),
        );
      },
    );

    // รอ 1 วินาทีก่อนปิด Popup และนำทาง
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop(); // ปิด Popup สำเร็จ
        _navigateToPage(page); // นำทางไปยังหน้าที่กำหนด
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              style: TextStyleService.getDmSans(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    "Enter your email address or username",
                                hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: Color(0xFFECF0F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                errorText: _emailError
                                    ? "This field is required"
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            Text(
                              "Password",
                              style: TextStyleService.getDmSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color: Color(0xFF000000)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: TextStyleService.getDmSans(
                                fontSize: 14, // ให้ใหญ่ขึ้นนิดเพื่อความชัด
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: Color(0xFFECF0F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      12), // ปรับให้กลมขึ้นนิด
                                  borderSide: BorderSide.none, // ไม่มีขอบ
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
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                errorText: _passwordError
                                    ? "This field is required"
                                    : null,
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
                                  "Forget Password?",
                                  style: TextStyleService.getDmSans(
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF64738B),
                                    fontSize: 16,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _validateAndLogin,
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
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                                            const Register(isProvider: true),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Register as Provider",
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
