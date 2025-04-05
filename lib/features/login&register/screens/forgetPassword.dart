import 'dart:convert';
import 'package:edugo/features/login&register/screens/login.dart';
import 'package:edugo/shared/utils/endpoint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool verifyOTP = false;

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Reset Successful",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green)),
          content: const Text("Return to Login", textAlign: TextAlign.center),
        );
      },
    );

    // รอ 3 วินาทีก่อนเปลี่ยนหน้า
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop(); // ปิด Popup
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const Login(),
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
    });
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

  Future<void> _sendResetLink() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog("Login Failed", "Invalid email or password.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog("Login Failed", "Invalid email or password.");
      return;
    }

    _showLoadingDialog(); // แสดง Popup Loading ก่อนเริ่ม request

    try {
      final response = await http.post(
        Uri.parse(Endpoints.forgotPassword),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          verifyOTP = true;
          Navigator.of(context).pop();
        });
      } else {
        final responseData = jsonDecode(response.body);
        _showError(responseData["error"] ?? "Something went wrong");
      }
    } catch (error) {
      _showError("Failed to connect to the server");
    }
  }

  Future<void> _verifyOTP() async {
    final String otp = _otpController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String email = _emailController.text.trim(); // รับค่า email

    if (otp.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty ||
        email.isEmpty) {
      _showErrorDialog("Reset Failed", "Invalid OTP");
      return;
    }

    if (newPassword != confirmPassword) {
      _showErrorDialog("Reset Failed", "Password must match confrim password");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(Endpoints.otpVerification),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email, // ส่ง email ไปด้วย
          "otp_code": otp,
          "new_password": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showErrorDialog("Reset Failed", "Invalid otp");
      }
    } catch (error) {
      _showErrorDialog("Reset Failed", "Invalid otp");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64.0),
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
              const SizedBox(height: 50),

              // Title & Description
              FractionallySizedBox(
                widthFactor: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verifyOTP ? "Verify OTP" : "Forgot Password",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      verifyOTP
                          ? "Enter the OTP sent to your email and set a new password."
                          : "Enter your email address, and we'll send you a reset link.",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF465468),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (!verifyOTP) ...[
                      const Text("Email",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w200, // ฟอนต์สำหรับข้อความที่พิมพ์
                          fontSize: 16,
                          color: Colors.black, // สีของข้อความที่พิมพ์
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter your email address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9.51),
                            borderSide: BorderSide.none, // ไม่มีขอบ
                          ),
                          filled: true,
                          fillColor: Color(0xFFECF0F6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            String emailOrUsername = _emailController.text;

                            // ตรวจสอบว่าอีเมล/ชื่อผู้ใช้และรหัสผ่านไม่ว่าง
                            if (emailOrUsername.isNotEmpty) {
                              _sendResetLink();
                            } else {
                              // แจ้งเตือนหากข้อมูลไม่ครบถ้วน
                              print(
                                  "Please enter your email/username and password");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF355FFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Send Reset Link",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly, // อนุญาตเฉพาะตัวเลข
                          LengthLimitingTextInputFormatter(
                              6), // จำกัดความยาว 6 ตัวอักษร
                        ],
                        style: TextStyle(
                          fontWeight: FontWeight.w200,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter 6-digit OTP",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9.51),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFFECF0F6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: !_isNewPasswordVisible,
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w200, // ฟอนต์สำหรับข้อความที่พิมพ์
                          fontSize: 16,
                          color: Colors.black, // สีของข้อความที่พิมพ์
                        ),
                        decoration: InputDecoration(
                          hintText: "New password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9.51),
                            borderSide: BorderSide.none, // ไม่มีขอบ
                          ),
                          filled: true,
                          fillColor: Color(0xFFECF0F6),
                          suffixIcon: IconButton(
                            icon: Icon(_isNewPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w200, // ฟอนต์สำหรับข้อความที่พิมพ์
                          fontSize: 16,
                          color: Colors.black, // สีของข้อความที่พิมพ์
                        ),
                        decoration: InputDecoration(
                          hintText: "Confirm password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9.51),
                            borderSide: BorderSide.none, // ไม่มีขอบ
                          ),
                          filled: true,
                          fillColor: Color(0xFFECF0F6),
                          suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF355FFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Reset Password",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
