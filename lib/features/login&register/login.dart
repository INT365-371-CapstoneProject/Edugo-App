import 'dart:convert';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/features/login&register/forgetPassword.dart';
import 'package:edugo/features/question/screens/question.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/profile/screens/profile.dart';

import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  bool _emailError = false;
  bool _passwordError = false;

  void _validateAndLogin() {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
    });

    if (!_emailError && !_passwordError) {
      loginUser(_emailController.text.trim(), _passwordController.text.trim());
    }
  }

  final AuthService _authService = AuthService();

  Future<void> loginUser(String emailOrUsername, String password) async {
    final url = Uri.parse('https://capstone24.sit.kmutt.ac.th/un2/api/login');

    _showLoadingDialog(); // แสดง Popup Loading ก่อนเริ่ม request

    // ตรวจสอบว่าเป็น Email หรือ Username
    bool isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailOrUsername);
    String key = isEmail ? 'email' : 'username';

    print(key);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          key: emailOrUsername, // ใช้ 'email' หรือ 'username' ตามที่ตรวจสอบได้
          'password': password,
          "remember_me": true
        }),
      );

      Navigator.of(context).pop(); // ปิด Popup Loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        await _authService.saveToken(token);

        _showSuccessDialog(); // แสดง Popup สำเร็จ
      } else {
        _showErrorDialog("Login Failed", "Invalid email or password.");
      }
    } catch (e) {
      Navigator.of(context).pop(); // ปิด Popup Loading
      _showErrorDialog("Error", "Something went wrong. Please try again.");
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
    final url = Uri.parse('https://capstone24.sit.kmutt.ac.th/un2/api/answer');
    final AuthService authService = AuthService();
    String? token = await authService.getToken();

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

  void _showSuccessDialog() {
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

    // รอ 1 วินาทีก่อนเรียก getAnswer()
    Future.delayed(const Duration(seconds: 1), () async {
      Navigator.of(context).pop(); // ปิด Popup

      final response = await getAnswer(); // ดึงข้อมูลจาก API

      if (response != null) {
        final data = json.decode(response.body);

        if (data["categories"].isEmpty &&
            data["countries"].isEmpty &&
            data["education_level"] == null) {
          // ถ้าข้อมูลไม่มีให้ไปหน้า Question
          _navigateToPage(const Question());
        } else {
          // ถ้าข้อมูลมีให้ไปหน้า HomeScreenApp
          _navigateToPage(const HomeScreenApp());
        }
      } else {
        // กรณี API error ให้ไปหน้า Question เป็น default
        _navigateToPage(const Question());
      }
    });
  }

  void _navigateToPage(Widget page) {
    Navigator.pushReplacement(
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
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(23.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64.0), // cf : 111
                  child: SizedBox(
                    width: 175,
                    height: 37.656,
                    child: Image.asset(
                      "assets/images/logoColor.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 51.34),

              // detail
              FractionallySizedBox(
                widthFactor: 1, // ให้เต็มความกว้างของหน้าจอ
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.49),
                    Text(
                      'Login to continue using the app',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w200,
                        color: Color(0xFF465468),
                      ),
                    ),
                    SizedBox(height: 63.51),
                    Text(
                      "Email / Username",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Enter your email address or username",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9.51),
                          borderSide: BorderSide(
                            color: _emailError
                                ? Colors.red
                                : Colors.transparent, // ขอบสีแดงถ้า error
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Color(0xFFECF0F6),
                        errorText: _emailError
                            ? "This field is required"
                            : null, // แสดงข้อความ error
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Text(
                      "Password",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9.51),
                          borderSide: BorderSide(
                            color: _passwordError
                                ? Colors.red
                                : Colors.transparent, // ขอบสีแดงถ้า error
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Color(0xFFECF0F6),
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
                            : null, // แสดงข้อความ error
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const ForgetPassword(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = 0.0;
                                const end = 1.0;
                                const curve = Curves.easeOut;

                                var tween = Tween(begin: begin, end: end)
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
                          "Forgot password?",
                          style: TextStyle(color: Color(0xFF64738B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
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
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Register Section
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Don’t have an account? ",
                          style: TextStyle(color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: "Register",
                              style: TextStyle(color: Colors.blue),
                              // Action for register
                              recognizer: null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
