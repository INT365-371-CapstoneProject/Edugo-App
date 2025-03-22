import 'dart:convert';
import 'package:edugo/features/login&register/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'package:edugo/features/home/screens/home_screen.dart';

class Register extends StatefulWidget {
  final bool isProvider;
  final bool isUser;
  const Register({super.key, this.isProvider = false, this.isUser = false});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool stepOne = true, stepTwo = false, stepThree = false;

  Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _controllers.addAll({
      'email': TextEditingController(),
      'password': TextEditingController(),
      'confirmPassword': TextEditingController(),
      'firstName': TextEditingController(),
      'lastName': TextEditingController(),
      'companyName': TextEditingController(),
      'website': TextEditingController(),
      'address': TextEditingController(),
      'city': TextEditingController(),
      'country': TextEditingController(),
      'postalCode': TextEditingController(),
      'phone': TextEditingController(),
      'username': TextEditingController(),
    });
  }

  Future<void> registerUser() async {
    String path = widget.isProvider
        ? "provider"
        : widget.isUser
            ? "user"
            : "";
    if (!_validateUserStepTwo()) return;

    final url = Uri.parse('https://capstone24.sit.kmutt.ac.th/un2/api/$path');
    final requestBody = _buildRequestBody();

    if (requestBody == null) return;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog(); // แสดง PopUp เมื่อสมัครสำเร็จ
      } else {
        _showErrorDialog("Registration Failed", response.body);
      }
    } catch (e) {
      _showErrorDialog("Error", "Something went wrong. Please try again.");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // กดข้างนอกแล้วไม่ปิด
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Success", textAlign: TextAlign.center),
          content: const Text("Your account has been successfully created!",
              textAlign: TextAlign.center),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Popup
                  _navigateToHome(); // ไปหน้า Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF355FFF),
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // กดข้างนอกแล้วไม่ปิด
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
                  Navigator.of(context).pop(); // ปิด Popup
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

  bool _validateUserStepOne() {
    setState(() {
      _errors.clear(); // เคลียร์ error ก่อนตรวจสอบ
    });

    final email = _controllers['email']!.text.trim();
    final username = _controllers['username']!.text.trim();
    final firstName = _controllers['firstName']!.text.trim();
    final lastName = _controllers['lastName']!.text.trim();

    bool isValid = true;

    // ตรวจสอบอีเมล
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (email.length == 0) {
      _errors['email'] = "Please enter your email address";
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _errors['email'] = "Invalid email format. Please enter a valid email";
      isValid = false;
    }

    // ตรวจสอบ Username, First Name และ Last Name
    if (username.length < 5) {
      _errors['username'] = "Username must be at least 5 characters long";
      isValid = false;
    }

    if (firstName.length < 2 || firstName.length > 25) {
      _errors['firstName'] =
          "First name must be between 2 and 25 characters long";
      isValid = false;
    }

    if (lastName.length < 2 || lastName.length > 25) {
      _errors['lastName'] =
          "Last name must be between 2 and 25 characters long";
      isValid = false;
    }

    setState(() {}); // อัปเดต UI

    return isValid;
  }

  bool _validateUserStepTwo() {
    setState(() {
      _errors.clear(); // ล้าง error ก่อนตรวจสอบใหม่
    });

    final password = _controllers['password']!.text.trim();
    final confirmPassword = _controllers['confirmPassword']!.text.trim();

    bool isValid = true;

    if (password.length < 6) {
      _errors['password'] = "Password must be at least 6 characters";
      isValid = false;
    }

    if (confirmPassword == '') {
      _errors['confirmPassword'] = "Confirm Password must match";
      isValid = false;
    } else if (password != confirmPassword) {
      _errors['confirmPassword'] = "Password and Confirm Password must match";
      isValid = false;
    }

    setState(() {}); // อัปเดต UI

    return isValid;
  }

  bool _validateProviderStepOne() {
    setState(() {
      _errors.clear(); // เคลียร์ error ก่อนตรวจสอบ
    });

    final email = _controllers['email']!.text.trim();
    final username = _controllers['username']!.text.trim();
    final firstName = _controllers['firstName']!.text.trim();
    final lastName = _controllers['lastName']!.text.trim();

    bool isValid = true;

    // ตรวจสอบอีเมล
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _errors['email'] = "Invalid email format";
      isValid = false;
    }

    // ตรวจสอบ Username, First Name และ Last Name
    if (username.length < 5) {
      _errors['username'] = "Must be at least 5 characters";
      isValid = false;
    }

    if (firstName.length < 2 || firstName.length > 25) {
      _errors['firstName'] = "Must be between 2 and 25 characters";
      isValid = false;
    }

    if (lastName.length < 2 || lastName.length > 25) {
      _errors['lastName'] = "Must be between 2 and 25 characters";
      isValid = false;
    }

    setState(() {}); // อัปเดต UI

    return isValid;
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const Login(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, dynamic>? _buildRequestBody() {
    final Map<String, dynamic> requestBody = {
      'email': _controllers['email']!.text.trim(),
      'username': _controllers['username']!.text.trim(),
      'password': _controllers['password']!.text.trim(),
      'confirm_password': _controllers['confirmPassword']!.text.trim(),
    };

    if (widget.isUser) {
      if (_controllers['firstName']!.text.isEmpty ||
          _controllers['lastName']!.text.isEmpty) {
        _showSnackBar("First Name and Last Name are required");
        return null;
      }
      requestBody.addAll({
        'first_name': _controllers['firstName']!.text.trim(),
        'last_name': _controllers['lastName']!.text.trim(),
      });
    } else if (widget.isProvider) {
      if (_controllers['companyName']!.text.isEmpty ||
          _controllers['address']!.text.isEmpty ||
          _controllers['city']!.text.isEmpty ||
          _controllers['country']!.text.isEmpty ||
          _controllers['postalCode']!.text.isEmpty ||
          _controllers['phone']!.text.isEmpty) {
        _showSnackBar("Please fill in all required fields");
        return null;
      }
      requestBody.addAll({
        'company_name': _controllers['companyName']!.text.trim(),
        'url': _controllers['website']!.text.trim(),
        'address': _controllers['address']!.text.trim(),
        'city': _controllers['city']!.text.trim(),
        'country': _controllers['country']!.text.trim(),
        'postal_code': _controllers['postalCode']!.text.trim(),
        'phone': _controllers['phone']!.text.trim(),
        'first_name': _controllers['firstName']!.text.trim(),
        'last_name': _controllers['lastName']!.text.trim(),
      });
    }

    return requestBody;
  }

  void _goToNextStep() {
    setState(() {
      if (stepOne && widget.isUser) {
        if (!_validateUserStepOne()) return;
        stepOne = false;
        stepTwo = true;
        print(_errors);
      } else if (stepTwo && widget.isUser) {
        if (!_validateUserStepTwo()) return;
        stepTwo = false;
      } else if (stepOne && widget.isProvider) {
        stepOne = false;
        stepTwo = true;
      } else if (stepTwo && widget.isProvider) {
        stepTwo = false;
        stepThree = true;
      }
    });
  }

  void _goToPreviousStep() {
    setState(() {
      if (stepThree) {
        stepThree = false;
        stepTwo = true;
      } else if (stepTwo) {
        stepTwo = false;
        stepOne = true;
      } else {
        Navigator.of(context).pop(); // ออกจากหน้าลงทะเบียน
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ป้องกันการ pop อัตโนมัติ
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goToPreviousStep();
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(23.0),
            child: Column(
              children: [
                SizedBox(
                    width: 175,
                    height: 37.656,
                    child: Image.asset("assets/images/logoColor.png")),
                const SizedBox(height: 30),
                ..._buildStepContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepContent() {
    if (widget.isUser) {
      if (stepOne) {
        return _buildUserStepOne();
      } else if (stepTwo) {
        return _buildUserStepTwo();
      }
    } else if (widget.isProvider) {
      if (stepOne) {
        return _buildProviderStepOne();
      } else if (stepTwo) {
        return _buildProviderStepTwo();
      } else if (stepThree) {
        return _buildProviderStepThree();
      }
    }
    return [];
  }

  List<Widget> _buildUserStepOne() {
    return [
      _buildSectionTitle("Register",
          "We’ll use your email to sign you in or to create an account if you don’t have one yet."),
      _buildLabeledTextField("Email", _controllers['email']!),
      _buildLabeledTextField("Username", _controllers['username']!),
      _buildLabeledTextField("First Name*", _controllers['firstName']!),
      _buildLabeledTextField("Last Name*", _controllers['lastName']!),
      _buildNextButton(),
    ];
  }

  List<Widget> _buildUserStepTwo() {
    return [
      _buildSectionTitle("Create a password",
          "Create a password at least 8 characters long or a number."),
      _buildLabeledTextField("Password", _controllers['password']!,
          isPassword: true),
      _buildLabeledTextField(
          "Confirm Password", _controllers['confirmPassword']!,
          isConfirmPassword: true),
      _buildCreateAccountButton(),
    ];
  }

  List<Widget> _buildProviderStepOne() {
    return [
      _buildSectionTitle(
          "Become our Scholarship Provider", "Fill in the details to proceed."),
      _buildLabeledTextField("Company Name*", _controllers['companyName']!),
      _buildLabeledTextField("Website", _controllers['website']!),
      _buildLabeledTextField("Address*", _controllers['address']!),
      _buildLabeledTextField("City*", _controllers['city']!),
      _buildLabeledTextField("Country*", _controllers['country']!),
      _buildLabeledTextField("Postal Code*", _controllers['postalCode']!),
      _buildLabeledTextField("Phone*", _controllers['phone']!),
      _buildNextButton(),
    ];
  }

  List<Widget> _buildProviderStepTwo() {
    return [
      _buildSectionTitle("Register",
          "We’ll use your email to sign you in or to create an account."),
      _buildLabeledTextField("Email", _controllers['email']!),
      _buildLabeledTextField("User Name*", _controllers['username']!),
      _buildLabeledTextField("First Name*", _controllers['firstName']!),
      _buildLabeledTextField("Last Name*", _controllers['lastName']!),
      _buildNextButton(),
    ];
  }

  List<Widget> _buildProviderStepThree() {
    return [
      _buildSectionTitle(
          "Create a password", "Create a password at least 8 characters long."),
      _buildLabeledTextField("Password", _controllers['password']!,
          isPassword: true),
      _buildLabeledTextField(
          "Confirm Password", _controllers['confirmPassword']!,
          isConfirmPassword: true),
      _buildCreateAccountButton(),
    ];
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Container(
      width: double.infinity, // บังคับให้ชิดซ้าย
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 27.34),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _goToNextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF355FFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text("Continue",
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF355FFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text("Create Account",
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildLabeledTextField(String label, TextEditingController controller,
      {bool isPassword = false, bool isConfirmPassword = false}) {
    final String key = _controllers.entries
        .firstWhere((entry) => entry.value == controller,
            orElse: () => MapEntry("", TextEditingController()))
        .key;
    final bool hasError =
        _errors.containsKey(key); // ตรวจสอบว่ามี error หรือไม่

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: (isPassword && !_isPasswordVisible) ||
                (isConfirmPassword && !_isConfirmPasswordVisible),
            decoration: InputDecoration(
              hintText: "Enter your ${label.split('*')[0].toLowerCase()}",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9.51),
                borderSide: hasError
                    ? const BorderSide(color: Colors.red, width: 2.0)
                    : BorderSide.none, // ใช้สีแดงตอนไม่ได้โฟกัส
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9.51),
                borderSide: hasError
                    ? const BorderSide(color: Colors.red, width: 2.0)
                    : BorderSide.none, // ใช้สีแดงตอนไม่ได้โฟกัส
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9.51),
                borderSide: hasError
                    ? const BorderSide(color: Colors.red, width: 2.0)
                    : BorderSide.none, // ใช้สี
              ),
              filled: true,
              fillColor: const Color(0xFFECF0F6),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    )
                  : isConfirmPassword
                      ? IconButton(
                          icon: Icon(_isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible),
                        )
                      : null,
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 5),
              child: Text(
                _errors[key]!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
