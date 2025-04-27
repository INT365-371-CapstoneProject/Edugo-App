import 'dart:convert';
import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/shared/utils/loading.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:edugo/main.dart'; // Import main.dart to access navigatorKey

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService(navigatorKey: navigatorKey);

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final FocusNode _isCurrentPasswordFocusNode = FocusNode();
  final FocusNode _NewPasswordFocusNode = FocusNode();
  final FocusNode _ConfirmPasswordFocusNode = FocusNode();

  bool currentPasswordError = false;
  bool newPasswordError = false;
  bool confirmPasswordError = false;
  bool currentPasswordFocused = false;
  bool newPasswordFocused = false;
  bool confirmPasswordFocused = false;

  bool isLengthValidPassword = false;
  bool isLowerPassword = false;
  bool isUpperPassword = false;
  bool isSpecialPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isCurrentPasswordFocusNode.addListener(() {
      setState(() {
        currentPasswordFocused = _isCurrentPasswordFocusNode.hasFocus;
      });
    });
    _NewPasswordFocusNode.addListener(() {
      setState(() {
        newPasswordFocused = _NewPasswordFocusNode.hasFocus;
      });
    });
    _ConfirmPasswordFocusNode.addListener(() {
      setState(() {
        confirmPasswordFocused = _ConfirmPasswordFocusNode.hasFocus;
      });
    });

    _newPasswordController.addListener(() {
      final text = _newPasswordController.text;
      setState(() {
        isLengthValidPassword = text.length >= 8;
        // isComplexityValid =
        //     RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[^A-Za-z0-9])').hasMatch(text);
        isLowerPassword = RegExp(r'[a-z]').hasMatch(text);
        isUpperPassword = RegExp(r'[A-Z]').hasMatch(text);
        isSpecialPassword = RegExp(r'[^A-Za-z0-9]').hasMatch(text);
      });
    });
  }

  void _validateChangePassword() {
    setState(() {
      currentPasswordError = _currentPasswordController.text.trim().isEmpty;
      newPasswordError = _newPasswordController.text.trim().isEmpty;
      confirmPasswordError = _confirmPasswordController.text.trim().isEmpty;

      // Only check for password match if the confirm field isn't empty
      if (!confirmPasswordError &&
          _confirmPasswordController.text.trim() !=
              _newPasswordController.text.trim()) {
        confirmPasswordError = true;
      }
    });

    if (!currentPasswordError && !newPasswordError && !confirmPasswordError) {
      _changePassword();
    }
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _showCustomLoadingDialog(context);

      String? token = await _authService.getToken();
      if (token == null) {
        _showErrorDialog("Error", "Authentication token not found.");
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context, rootNavigator: true)
            .pop(); // Close loading dialog
        return;
      }

      try {
        // Change http.put to http.post
        final response = await http.post(
          Uri.parse(ApiConfig.profileChangePasswordUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'current_password': _currentPasswordController.text,
            'new_password': _newPasswordController.text,
          }),
        );

        Navigator.of(context, rootNavigator: true)
            .pop(); // Close loading dialog

        if (response.statusCode == 200) {
          _showSuccessUserDialog();
        } else {
          final responseData = json.decode(response.body);
          _showErrorDialog(
              "Change Password Failed",
              responseData['message'] ??
                  "An error occurred. Please check your current password and try again.");
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true)
            .pop(); // Close loading dialog
        // Add more specific error handling for FormatException if needed
        if (e is FormatException) {
          _showErrorDialog("Error", "Invalid response format from server.");
        } else {
          _showErrorDialog("Error", "Failed to connect to the server. $e");
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
                    "We're changing your password",
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

  void _showSuccessUserDialog() {
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
                    "Changed Successful",
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your Password has been changed.",
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
                        Navigator.pop(context);
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
                        "Back to Profile",
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

  void _showErrorDialog(String title, String message) {
    if (Navigator.canPop(context)) {}
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: SizedBox(
            width: 300,
            height: 400,
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
                      fontSize: 20,
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF355FFF),
              padding: const EdgeInsets.only(
                top: 72.0,
                right: 16,
                left: 16,
                bottom: 22,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // Navigator.push(
                      //   context,
                      //   PageRouteBuilder(
                      //     pageBuilder: (context, animation, secondaryAnimation) =>
                      //         const PersonalProfile(),
                      //     transitionsBuilder:
                      //         (context, animation, secondaryAnimation, child) {
                      //       const begin = 0.0;
                      //       const end = 1.0;
                      //       const curve = Curves.easeOut;
                      //       var tween = Tween(begin: begin, end: end)
                      //           .chain(CurveTween(curve: curve));
                      //       return FadeTransition(
                      //           opacity: animation.drive(tween), child: child);
                      //     },
                      //     transitionDuration: const Duration(milliseconds: 300),
                      //   ),
                      // );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFDAFB59),
                      child: Image.asset(
                        'assets/images/back_button.png',
                        width: 20.0,
                        height: 20.0,
                        color: const Color(0xFF355FFF),
                      ),
                    ),
                  ),
                  Text(
                    "Change Password",
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF355FFF),
                      // child: Image.asset(
                      //   'assets/images/notification.png',
                      //   width: 40.0,
                      //   height: 40.0,
                      // ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPasswordField(
                      label: "Current Password",
                      controller: _currentPasswordController,
                      isVisible: _isCurrentPasswordVisible,
                      focusNode: _isCurrentPasswordFocusNode,
                      focused: currentPasswordFocused,
                      error: currentPasswordError,
                      toggleVisibility: () {
                        setState(() {
                          _isCurrentPasswordVisible =
                              !_isCurrentPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                      hint: 'Enter your current password',
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      label: "New Password",
                      controller: _newPasswordController,
                      isVisible: _isNewPasswordVisible,
                      focusNode: _NewPasswordFocusNode,
                      focused: newPasswordFocused,
                      error: newPasswordError,
                      toggleVisibility: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          // Consistent with register validation
                          return 'Password must be at least 6 characters';
                        }
                        if (value == _currentPasswordController.text) {
                          return "The new password cannot be the same as the current password";
                        }
                        return null; // Password is valid
                      },
                      hint: 'Enter your new password',
                    ),
                    SizedBox(height: 8),
                    _buildRequirement(
                        isLengthValidPassword, 'Must be least 8 characters'),
                    SizedBox(height: 4),
                    _buildRequirement(
                        isLowerPassword, '1 Lowercase character (a-z)'),
                    SizedBox(height: 4),
                    _buildRequirement(
                        isUpperPassword, "1 uppercase character (a-z)"),
                    SizedBox(height: 4),
                    _buildRequirement(isSpecialPassword,
                        "At least 1 special character (e.g. ! @ # \$ % .)"),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      label: "Confirm Password",
                      controller: _confirmPasswordController,
                      isVisible: _isConfirmPasswordVisible,
                      focusNode: _ConfirmPasswordFocusNode,
                      focused: confirmPasswordFocused,
                      error: confirmPasswordError,
                      toggleVisibility: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      hint: 'Confirm your new password',
                      customErrorText:
                          "Confirm password must match new password", // Add this line
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _validateChangePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF355FFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text(
                    "Change Password",
                    style: TextStyleService.getDmSans(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
    required String hint,
    required bool focused,
    required bool error,
    required FocusNode focusNode,
    String? customErrorText, // Add this parameter
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: TextStyleService.getDmSans(
            fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Color(0xFFECF0F6),
          borderRadius: BorderRadius.circular(15),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: error
                        ? Color.fromRGBO(237, 75, 158, 0.15)
                        : Color.fromRGBO(108, 99, 255, 0.15),
                    blurRadius: 0,
                    spreadRadius: 6,
                    offset: Offset(0, 0),
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: !isVisible,
          style: TextStyleService.getDmSans(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: "Enter your ${label.toLowerCase()}",
            hintStyle: TextStyleService.getDmSans(
              color: Colors.black.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.51),
              borderSide: error
                  ? const BorderSide(color: Colors.red, width: 2.0)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.51),
              borderSide: error
                  ? const BorderSide(color: Colors.red, width: 2.0)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9.51),
              borderSide: error
                  ? const BorderSide(color: Colors.red, width: 2.0)
                  : const BorderSide(color: Color(0xFFC0CDFF)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFFCBD5E0),
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ),
      if (error) ...[
        const SizedBox(height: 8),
        Text(
          // For confirm password: show default message if field is empty, custom message if passwords don't match
          (label == "Confirm Password" && controller.text.trim().isNotEmpty)
              ? customErrorText ?? "Please enter your ${label.toLowerCase()}"
              : "Please enter your ${label.toLowerCase()}",
          style: TextStyleService.getDmSans(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ]);
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
}
