import 'dart:convert';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/shared/utils/customBackButton.dart';
import 'package:edugo/shared/utils/loading.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:edugo/config/api_config.dart';

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
  bool isLengthValidPassword = false;
  bool isLowerPassword = false;
  bool isUpperPassword = false;
  bool isSpecialPassword = false;
  bool isNumberPassword = false;

  bool verifyOTP = false;
  String? _emailErrorText;
  String? _otpErrorText;
  String? _newPasswordErrorText;
  String? _confirmPasswordErrorText;
  bool _emailError = false;

  @override
  void initState() {
    super.initState();

    _newPasswordController.addListener(() {
      final text = _newPasswordController.text;
      final hasNumber = RegExp(r'\d').hasMatch(text);
      setState(() {
        isLengthValidPassword = text.length >= 8;
        isLowerPassword = RegExp(r'[a-z]').hasMatch(text);
        isUpperPassword = RegExp(r'[A-Z]').hasMatch(text);
        isSpecialPassword = RegExp(r'[^A-Za-z0-9]').hasMatch(text);
        isNumberPassword = hasNumber;
      });
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  void _validateEmail() {
    final email = _emailController.text.trim();

    setState(() {
      if (email.isEmpty) {
        _emailErrorText = "Please enter your email address";
      } else if (!_isValidEmail(email)) {
        _emailErrorText =
            "Please enter a valid email address (Ex. example@gmail.com)";
      } else {
        _emailErrorText = null;
      }
    });

    if (_emailErrorText == null) {
      _sendResetLink();
    }
  }

  void _validateVerify() {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      if (otp.isEmpty) {
        _otpErrorText = "Please enter the OTP";
      } else if (otp.length != 6) {
        _otpErrorText = "OTP must be 6 digits";
      } else {
        _otpErrorText = null;
      }

      if (newPassword.isEmpty) {
        _newPasswordErrorText = "Please enter a new password";
      } else if (!isLowerPassword) {
        _newPasswordErrorText =
            "Password must contain at least 1 lowercase letter";
      } else if (!isUpperPassword) {
        _newPasswordErrorText =
            "Password must contain at least 1 uppercase letter";
      } else if (!isNumberPassword) {
        _newPasswordErrorText = "Password must contain at least 1 number.";
      } else if (!isSpecialPassword) {
        _newPasswordErrorText =
            "Password must contain at least 1 special character";
      } else if (!isLengthValidPassword) {
        _newPasswordErrorText = "Password must be at least 8 characters";
      } else {
        _newPasswordErrorText = null;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordErrorText = "Please confirm your password";
      } else if (confirmPassword != newPassword) {
        _confirmPasswordErrorText = "Passwords do not match";
      } else {
        _confirmPasswordErrorText = null;
      }
    });

    if (_otpErrorText == null &&
        _newPasswordErrorText == null &&
        _confirmPasswordErrorText == null) {
      _verifyOTP();
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
                    "We're going to send you a reset link to your email.",
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

  void _showSuccessDialog(Widget page) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 300,
            height: 360, // ปรับความสูงเพิ่มนิดเพื่อใส่ปุ่ม
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
                    "Reset Password Success",
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You can now login with your new password.",
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // ปิด Loading Dialog
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const Login(),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Go to login",
                        style: TextStyleService.getDmSans(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
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

  Future<void> _sendResetLink() async {
    final String email = _emailController.text.trim();

    _showCustomLoadingDialog(context); // แสดง Popup Loading ก่อนเริ่ม request

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordUrl),
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
        Navigator.of(context).pop();
        _showErrorDialog("Reset Link Failed", responseData["error"]);
      }
    } catch (error) {
      _showErrorDialog("Failed to connect to the server", "Please try again.");
    }
  }

  Future<void> _verifyOTP() async {
    _showCustomLoadingDialog(context);
    final String otp = _otpController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String email = _emailController.text.trim(); // รับค่า email

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtpUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email, // ส่ง email ไปด้วย
          "otp_code": otp,
          "new_password": newPassword,
        }),
      );
      Navigator.of(context).pop();
      if (response.statusCode == 200) {
        _showSuccessDialog(const Login());
      } else {
        Navigator.of(context).pop(); // ปิด Popup
        _showErrorDialog("Reset Failed", "Invalid otp");
      }
    } catch (error) {
      Navigator.of(context).pop(); // ปิด Popup
      _showErrorDialog("Reset Failed", "Invalid otp");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyleService.getDmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        backgroundColor: Colors.red,
      ),
    );
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
                          horizontal: 64, vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 111.0),
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
                  const SizedBox(height: 24),

                  // Title & Description
                  FractionallySizedBox(
                    widthFactor: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verifyOTP ? "Verify OTP" : "Forgot Password",
                          style: TextStyleService.getDmSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        SizedBox(height: 6.49),
                        Text(
                          verifyOTP
                              ? "Enter the OTP sent to your email and set a new password."
                              : "Enter your email address, and we'll send you a reset link.",
                          style: TextStyleService.getDmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF465468),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!verifyOTP) ...[
                          Text("Email",
                              style: TextStyleService.getDmSans(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6.49),
                          TextField(
                            controller: _emailController,
                            style: TextStyleService.getDmSans(
                              fontWeight: FontWeight.w200,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  "Enter your email address (Ex. example@gmail.com)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _emailErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _emailErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _emailErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : const BorderSide(
                                        color: Color(0xFFC0CDFF)),
                              ),
                              filled: true,
                              fillColor: Color(0xFFECF0F6),
                            ),
                          ),
                          if (_emailErrorText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                _emailErrorText!,
                                style: TextStyleService.getDmSans(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          const SizedBox(height: 50),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                _validateEmail();
                                // _sendResetLink();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF355FFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Send Reset Link",
                                style: TextStyleService.getDmSans(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
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
                            style: TextStyleService.getDmSans(
                              fontWeight: FontWeight.w200,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter 6-digit OTP",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _otpErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _otpErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _otpErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : const BorderSide(
                                        color: Color(0xFFC0CDFF)),
                              ),
                              filled: true,
                              fillColor: Color(0xFFECF0F6),
                            ),
                          ),
                          if (_otpErrorText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                _otpErrorText!,
                                style: TextStyleService.getDmSans(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: !_isNewPasswordVisible,
                            style: TextStyleService.getDmSans(
                              fontWeight:
                                  FontWeight.w200, // ฟอนต์สำหรับข้อความที่พิมพ์
                              fontSize: 16,
                              color: Colors.black, // สีของข้อความที่พิมพ์
                            ),
                            decoration: InputDecoration(
                              hintText: "New password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _newPasswordErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _newPasswordErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _newPasswordErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : const BorderSide(
                                        color: Color(0xFFC0CDFF)),
                              ),
                              filled: true,
                              fillColor: Color(0xFFECF0F6),
                              suffixIcon: IconButton(
                                icon: Icon(_isNewPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _isNewPasswordVisible =
                                        !_isNewPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          if (_newPasswordErrorText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                _newPasswordErrorText!,
                                style: TextStyleService.getDmSans(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          SizedBox(height: 8),
                          _buildRequirement(isLengthValidPassword,
                              'Must be least 8 characters'),
                          SizedBox(height: 4),
                          _buildRequirement(
                              isLowerPassword, '1 Lowercase character (a-z)'),
                          SizedBox(height: 4),
                          _buildRequirement(
                              isUpperPassword, "1 uppercase character (a-z)"),
                          SizedBox(height: 4),
                          _buildRequirement(
                              isNumberPassword, "At least 1 number (0-9)"),
                          SizedBox(height: 4),
                          _buildRequirement(isSpecialPassword,
                              "At least 1 special character (e.g. ! @ # \$ % .)"),
                          SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            style: TextStyleService.getDmSans(
                              fontWeight:
                                  FontWeight.w200, // ฟอนต์สำหรับข้อความที่พิมพ์
                              fontSize: 16,
                              color: Colors.black, // สีของข้อความที่พิมพ์
                            ),
                            decoration: InputDecoration(
                              hintText: "Confirm password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _confirmPasswordErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _confirmPasswordErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9.51),
                                borderSide: _confirmPasswordErrorText != null
                                    ? const BorderSide(
                                        color: Colors.red, width: 2.0)
                                    : const BorderSide(
                                        color: Color(0xFFC0CDFF)),
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
                          if (_confirmPasswordErrorText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                _confirmPasswordErrorText!,
                                style: TextStyleService.getDmSans(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _validateVerify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF355FFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Reset Password",
                                style: TextStyleService.getDmSans(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
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
          CustomBackButton(),
        ],
      ),
    );
  }
}

Widget _buildRequirement(bool isValid, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0.0),
    child: Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? Colors.green : Color(0xFF94A2B8),
          size: 12,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyleService.getDmSans(
            fontWeight: FontWeight.w200,
            color: isValid ? Colors.green : Color(0xFF94A2B8),
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}
