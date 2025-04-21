import 'dart:convert';
import 'dart:math';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/shared/utils/customBackButton.dart';
import 'package:edugo/shared/utils/loading.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/config/api_config.dart';

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
  bool isLengthValidPassword = false;
  bool isLowerPassword = false;
  bool isUpperPassword = false;
  bool isSpecialPassword = false;
  // bool isComplexityValid = false;
  Map<String, String?> _errors = {};
  // List<String> _countries = [];
  // String? _selectedCountry;
  // bool _isLoading = true;
  // List<String> _cities = [];

  // String? _selectedCity;

  @override
  void initState() {
    super.initState();
    // fetchCountries();
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

    _controllers['password']?.addListener(() {
      final text = _controllers['password']!.text;
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

  // Future<void> fetchCountries() async {
  //   final url =
  //       Uri.parse('https://countriesnow.space/api/v0.1/countries/positions');

  //   try {
  //     final response = await http.get(url);
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final List countriesData = data['data'];
  //       setState(() {
  //         _countries = countriesData
  //             .map<String>((item) => item['name'] as String)
  //             .toList();
  //         _isLoading = false;
  //       });
  //     } else {
  //       throw Exception("Failed to load countries");
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     print("Error fetching countries: $e");
  //   }
  // }

  // Future<void> fetchCities(String country) async {
  //   final url = Uri.parse(
  //     'https://countriesnow.space/api/v0.1/countries/cities/q?country=${Uri.encodeQueryComponent(country)}',
  //   );

  //   try {
  //     final response = await http.get(url);

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final List<dynamic> citiesData = data['data'];
  //       setState(() {
  //         _cities = citiesData.cast<String>();
  //         _selectedCity = null;
  //       });
  //     } else {
  //       print(response.body);
  //       throw Exception("Failed to load cities");
  //     }
  //   } catch (e) {
  //     print("Error fetching cities: $e");
  //   }
  // }

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

  Future<void> registerUser() async {
    String path = widget.isProvider ? "provider" : "user";
    final url = Uri.parse('${ApiConfig.apiUrl}/$path');
    if (!_validateUserStepTwo()) return;

    final requestBody = _buildRequestBody();
    if (requestBody == null) return;

    _showCustomLoadingDialog(context);

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
        if (mounted) {
          Navigator.pop(context); // ปิด Loading Dialog
        }
        widget.isProvider
            ? _showSuccessProviderDialog()
            : _showSuccessUserDialog(Login());
      } else {
        String errorMessage = "Registration failed. Please try again.";

        try {
          final decoded = json.decode(response.body);
          if (decoded is Map) {
            if (decoded.containsKey('error')) {
              errorMessage = decoded['error'];
            } else if (decoded.containsKey('message')) {
              errorMessage = decoded['message'];
            }
          }
        } catch (e) {
          // Handle JSON decoding error if needed
          print("Error decoding response: $e");
        }

        _showErrorDialog("Registration Failed", errorMessage);
      }
    } catch (e) {
      _showErrorDialog("Error", "Something went wrong. Please try again.");
    }
  }

  void _showSuccessProviderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.only(top: 40),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 19, vertical: 24),
          actionsPadding: const EdgeInsets.only(bottom: 25),
          title: Column(
            children: [
              SizedBox(
                  height: 131,
                  width: 132,
                  child: SvgPicture.asset("assets/images/waiting.svg")),
              const SizedBox(height: 0),
            ],
          ),
          content: Text(
            "Your account is under review.\nOur team will approve it within\n1-2 business days, and we’ll\nnotify you as soon as it's ready.",
            textAlign: TextAlign.center,
            style: TextStyleService.getDmSans(
                fontSize: 14,
                color: Color(0xFF000000),
                fontWeight: FontWeight.w400,
                height: 1.7),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 19.0),
                child: SizedBox(
                  width: double.infinity, // ความกว้างที่ต้องการ
                  height: 56, // ความสูงที่ต้องการ
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // ปิด Popup
                      _navigateToHome(); // ไปที่หน้า Home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF355FFF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Let’s Discover",
                      style: TextStyleService.getDmSans(
                          fontSize: 14,
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessUserDialog(Widget page) {
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
                    "Registration Successful",
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You can now log in to your account.",
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
                        _navigateToHome(); // ไปที่หน้า Home
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

  // void _showSuccessUserDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.white,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         titlePadding: const EdgeInsets.only(top: 24),
  //         contentPadding:
  //             const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  //         actionsPadding: const EdgeInsets.only(bottom: 16),
  //         title: Column(
  //           children: [
  //             Icon(Icons.check_circle_outline, color: Colors.green, size: 150),
  //             const SizedBox(height: 12),
  //             Text(
  //               "Registration Successful",
  //               textAlign: TextAlign.center,
  //               style: TextStyleService.getDmSans(
  //                 color: Colors.green,
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Text(
  //           "Your account has been created.\nYou can now log in to your account.",
  //           textAlign: TextAlign.center,
  //           style: TextStyleService.getDmSans(
  //               fontSize: 16,
  //               color: Colors.black87,
  //               fontWeight: FontWeight.w400),
  //         ),
  //         actions: [
  //           Center(
  //             child: ElevatedButton(
  //               onPressed: () {
  //                 _navigateToHome(); // ไปที่หน้า Home
  //               },
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.green,
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 elevation: 0,
  //               ),
  //               child: Text(
  //                 "Go to login",
  //                 style: TextStyleService.getDmSans(
  //                     fontSize: 16,
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.w600),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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

  bool _validateUserStepOne() {
    setState(() {
      _errors.clear(); // เคลียร์ error ก่อนตรวจสอบ
    });

    final email = _controllers['email']!.text.trim();
    final username = _controllers['username']!.text.trim();
    final firstName = _controllers['firstName']!.text.trim();
    final lastName = _controllers['lastName']!.text.trim();

    bool isValid = true;

    if (email.length == 0) {
      _errors['email'] = "Please enter your email address";
      isValid = false;
    } else if (!EmailValidator.validate(email)) {
      _errors['email'] = "Invalid email format. Ex: example@gmail.com";
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

    if (!isLengthValidPassword) {
      _errors['password'] = "Password must be between 8 and 20 characters";
      isValid = false;
    }
    if (!isUpperPassword) {
      _errors['password'] =
          "Password must contain letters, numbers, and special characters";
      isValid = false;
    } else if (!isLowerPassword) {
      _errors['password'] =
          "Password must contain letters, numbers, and special characters";
      isValid = false;
    } else if (!isSpecialPassword) {
      _errors['password'] =
          "Password must contain letters, numbers, and special characters";
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

    final companyName = _controllers['companyName']!.text.trim();
    final address = _controllers['address']!.text.trim();
    final city = _controllers['city']!.text.trim();
    final country = _controllers['country']!.text.trim();
    final postalCode = _controllers['postalCode']!.text.trim();
    final phone = _controllers['phone']!.text.trim();
    final website = _controllers['website']!.text.trim();

    bool isValid = true;

    // ตรวจสอบ Username, First Name และ Last Name
    if (companyName.isEmpty) {
      _errors['companyName'] = "Company Name is required";
      isValid = false;
    } else if (companyName.length < 5) {
      _errors['companyName'] =
          "Company name must be at least 5 characters long";
      isValid = false;
    }

    if (address.isEmpty) {
      _errors['address'] = "Address is required";
      isValid = false;
    } else if (address.length < 5) {
      _errors['address'] = "Address must be at least 5 characters long";
      isValid = false;
    } else if (address.length > 100) {
      _errors['address'] = "Address must be less than 100 characters long";
      isValid = false;
    }

    if (city.isEmpty) {
      _errors['city'] = "City is required";
      isValid = false;
    } else if (city.length < 5) {
      _errors['city'] = "City must be at least 5 characters long";
      isValid = false;
    } else if (city.length > 100) {
      _errors['city'] = "City must be less than 100 characters long";
      isValid = false;
    }

    if (country.isEmpty) {
      _errors['country'] = "Country is required";
      isValid = false;
    } else if (country.length < 5) {
      _errors['country'] = "Country must be at least 5 characters long";
      isValid = false;
    } else if (country.length > 100) {
      _errors['country'] = "Country must be less than 100 characters long";
      isValid = false;
    }
    if (postalCode.isEmpty) {
      _errors['postalCode'] = "Postal Code is required";
      isValid = false;
    } else if (postalCode.length < 5) {
      _errors['postalCode'] = "Postal Code must be at least 5 characters long";
      isValid = false;
    } else if (postalCode.length > 20) {
      _errors['postalCode'] =
          "Postal Code must be less than 20 characters long";
      isValid = false;
    }
    if (phone.isEmpty) {
      _errors['phone'] = "Phone is required";
      isValid = false;
    } else if (phone.length < 8) {
      _errors['phone'] = "Phone must be at least 8 digit";
      isValid = false;
    }

    if (website.isNotEmpty) {
      final websitePattern =
          RegExp(r'^https:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(\/.*)?$');
      if (!websitePattern.hasMatch(website)) {
        _errors['website'] =
            "Website must start with https:// and contain a valid domain (e.g. .com, .org)";
        isValid = false;
      }
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
        if (!_validateProviderStepOne()) return;
        stepOne = false;
        stepTwo = true;
      } else if (stepTwo && widget.isProvider) {
        if (!_validateUserStepOne()) return;
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      // ปิด auto resize ตอนคีย์บอร์ดขึ้น
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ใช้ SingleChildScrollView และเลื่อนได้แม้ resize ถูกปิด
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const SizedBox(height: 111),
                  Center(
                    child: SizedBox(
                      width: 175,
                      height: 37.656,
                      child: Image.asset("assets/images/logoColor.png",
                          fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    child: Column(children: _buildStepContent()),
                  ),
                ],
              ),
            ),
          ),

          // ปุ่มย้อนกลับ
          // CustomBackButton(pageToNavigate: const Login()),

          Positioned(
            top: 63.0,
            left: 22.0,
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: const Color(0xFFCBD5E0),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4.0),
                  onTap: () {
                    setState(() {
                      if (stepThree) {
                        stepThree = false;
                        stepTwo = true;
                      } else if (stepTwo) {
                        stepTwo = false;
                        stepOne = true;
                      } else if (stepOne) {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    Login(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = 0.0;
                              const end = 1.0;
                              const curve = Curves.easeOut;
                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              return FadeTransition(
                                  opacity: animation.drive(tween),
                                  child: child);
                            },
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        );
                      }
                    });
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 9.0,
                      height: 15.0,
                      child: SvgPicture.asset(
                        'assets/images/back.svg',
                        fit: BoxFit.cover,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ปุ่มด้านล่าง — แยกไว้แบบไม่ให้คีย์บอร์ดดัน
          Positioned(
            left: 22,
            right: 22,
            bottom: 30,
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: _buildBottomButton(),
            ),
          ),
        ],
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
        return _buildUserStepOne();
      } else if (stepThree) {
        return _buildUserStepTwo();
      }
    }
    return [];
  }

  List<Widget> _buildUserStepOne() {
    return [
      _buildSectionTitle("Register",
          "We’ll use your email to sign you in or to create an account if you don’t have one yet."),
      SizedBox(height: 23.85),
      _buildLabeledTextField("Email*", _controllers['email']!),
      SizedBox(height: 12),
      _buildLabeledTextField("Username*", _controllers['username']!),
      SizedBox(height: 12),
      _buildLabeledTextField("First Name*", _controllers['firstName']!),
      SizedBox(height: 12),
      _buildLabeledTextField("Last Name*", _controllers['lastName']!),
      SizedBox(height: 52),
      // _buildNextButton(),
    ];
  }

  List<Widget> _buildUserStepTwo() {
    return [
      _buildSectionTitle("Create a password",
          "Create a password at least 8 characters long or\nnumber."),
      SizedBox(height: 15.51),
      _buildLabeledTextField("Password", _controllers['password']!,
          isPassword: true),
      SizedBox(height: 8),
      _buildRequirement(isLengthValidPassword, 'Must be least 8 characters'),
      SizedBox(height: 4),
      _buildRequirement(isLowerPassword, '1 Lowercase character (a-z)'),
      SizedBox(height: 4),
      _buildRequirement(isUpperPassword, "1 uppercase character (a-z)"),
      SizedBox(height: 4),
      _buildRequirement(isSpecialPassword,
          "At least 1 special character (e.g. ! @ # \$ % .)"),
      const SizedBox(height: 8),
      SizedBox(height: 16),
      _buildLabeledTextField(
          "Confirm Password", _controllers['confirmPassword']!,
          isConfirmPassword: true),
      SizedBox(height: 128),
      // _buildCreateAccountButton(),
    ];
  }

  List<Widget> _buildProviderStepOne() {
    return [
      _buildSectionTitle(
          "Become our Scholarship Provider", "Fill in the details to proceed."),
      SizedBox(height: 23.85),
      _buildLabeledTextField("Company Name*", _controllers['companyName']!),
      SizedBox(height: 12),
      _buildLabeledTextField("Website", _controllers['website']!),
      SizedBox(height: 12),
      _buildLabeledTextField("Address*", _controllers['address']!),
      SizedBox(height: 12),
      _buildLabeledTextField("Country*", _controllers['country']!),
      SizedBox(height: 12),
      _buildLabeledTextField("City*", _controllers['city']!),
      SizedBox(height: 12),

      _buildLabeledTextField("Postal Code*", _controllers['postalCode']!),
      SizedBox(height: 12),
      _buildLabeledTextField("Phone*", _controllers['phone']!),
      // _buildNextButton(),
    ];
  }

  List<Widget> _buildProviderStepTwo() {
    return [
      _buildSectionTitle("Register",
          "We’ll use your email to sign you in or to create an account."),
      SizedBox(height: 23.85),
      _buildLabeledTextField("Email", _controllers['email']!),
      SizedBox(height: 12),
      _buildLabeledTextField("User Name*", _controllers['username']!),
      SizedBox(height: 12),
      _buildLabeledTextField("First Name*", _controllers['firstName']!),
      SizedBox(height: 18),
      _buildLabeledTextField("Last Name*", _controllers['lastName']!),
      // _buildNextButton(),
    ];
  }

  List<Widget> _buildProviderStepThree() {
    return [
      _buildSectionTitle(
          "Create a password", "Create a password at least 8 characters long."),
      SizedBox(height: 23.85),
      _buildLabeledTextField("Password", _controllers['password']!,
          isPassword: true),
      _buildLabeledTextField(
          "Confirm Password", _controllers['confirmPassword']!,
          isConfirmPassword: true),
      //_buildCreateAccountButton(),
    ];
  }

  Widget _buildBottomButton() {
    // เช็คว่าต้องแสดงปุ่มอะไร
    if (widget.isUser) {
      if (stepOne || stepTwo) {
        return stepOne ? _buildNextButton() : _buildCreateAccountButton();
      }
    } else if (widget.isProvider) {
      if (stepOne || stepTwo || stepThree) {
        if (stepOne || stepTwo) return _buildNextButton();
        return _buildCreateAccountButton();
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Container(
      width: double.infinity, // บังคับให้ชิดซ้าย
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyleService.getDmSans(
                  fontSize: 24, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.49),
            Text(
              subtitle,
              style: TextStyleService.getDmSans(
                  fontSize: 16, fontWeight: FontWeight.w200),
            ),
          ],
        ),
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
        child: Text("Continue",
            style: TextStyleService.getDmSans(
                fontSize: 14,
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.w600)),
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
        child: Text("Create Account",
            style: TextStyleService.getDmSans(
                fontSize: 16,
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLabeledTextField(String label, TextEditingController controller,
      {bool isPassword = false, bool isConfirmPassword = false}) {
    final String key = _controllers.entries
        .firstWhere((entry) => entry.value == controller,
            orElse: () => MapEntry("", TextEditingController()))
        .key;
    final bool hasError = _errors.containsKey(key);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label.contains('*') ? label.split('*')[0] : label,
              style: TextStyleService.getDmSans(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
              ),
              children: label.contains('*')
                  ? [
                      TextSpan(
                        text: '*',
                        style: TextStyleService.getDmSans(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
          SizedBox(height: 12),

          // ✅ เงื่อนไขพิเศษสำหรับ Country ให้ใช้ Dropdown
          // if (key == 'country')
          //   DropdownButtonFormField<String>(
          //     isExpanded: true,
          //     value:
          //         _countries.contains(controller.text) ? controller.text : null,
          //     items: _countries.map((String country) {
          //       return DropdownMenuItem<String>(
          //         value: country,
          //         child: Text(
          //           country,
          //           overflow: TextOverflow.ellipsis,
          //           style: TextStyleService.getDmSans(
          //             fontSize: 16,
          //             fontWeight: FontWeight.w200,
          //           ),
          //         ),
          //       );
          //     }).toList(),
          //     onChanged: (value) {
          //       if (value != null) {
          //         setState(() {
          //           _selectedCountry = value;
          //           _controllers['country']?.text = value;

          //           // Reset city when country changes
          //           _selectedCity = null;
          //           _controllers['city']?.text = ''; // or null as required
          //         });
          //         fetchCities(value); // Fetch cities again
          //       }
          //     },
          //     decoration: InputDecoration(
          //       isDense: true,
          //       contentPadding:
          //           const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(9.51),
          //         borderSide: hasError
          //             ? const BorderSide(color: Colors.red, width: 2.0)
          //             : BorderSide.none,
          //       ),
          //       enabledBorder: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(9.51),
          //         borderSide: hasError
          //             ? const BorderSide(color: Colors.red, width: 2.0)
          //             : BorderSide.none,
          //       ),
          //       focusedBorder: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(9.51),
          //         borderSide: hasError
          //             ? const BorderSide(color: Colors.red, width: 2.0)
          //             : const BorderSide(color: Color(0xFFECF0F6)),
          //       ),
          //       filled: true,
          //       fillColor: const Color(0xFFECF0F6),
          //     ),
          //     hint: Text(
          //       "Please select your country",
          //       style: TextStyleService.getDmSans(
          //         fontSize: 16,
          //         fontWeight: FontWeight.w200,
          //         color: Color(0xFF000000),
          //       ),
          //     ),
          //   )
          // else if (key == 'city')
          //   DropdownButtonFormField<String>(
          //     isExpanded: true,
          //     value: _cities.contains(controller.text)
          //         ? controller.text
          //         : null, // ตรวจสอบว่า controller.text มีใน _cities
          //     items: _cities.map((String city) {
          //       return DropdownMenuItem<String>(
          //         value: city,
          //         child: Text(
          //           city,
          //           overflow: TextOverflow.ellipsis,
          //           style: TextStyleService.getDmSans(
          //             fontSize: 16,
          //             fontWeight: FontWeight.w200,
          //           ),
          //         ),
          //       );
          //     }).toList(),
          //     onChanged: (value) {
          //       if (value != null) {
          //         setState(() {
          //           _selectedCity = value;
          //           controller.text = value;
          //         });
          //       }
          //     },
          //     decoration: InputDecoration(
          //       isDense: true,
          //       contentPadding: const EdgeInsets.symmetric(
          //         vertical: 16,
          //         horizontal: 16,
          //       ),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(9.51),
          //         borderSide: hasError
          //             ? const BorderSide(color: Colors.red, width: 2.0)
          //             : BorderSide.none,
          //       ),
          //       enabledBorder: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(9.51),
          //         borderSide: hasError
          //             ? const BorderSide(color: Colors.red, width: 2.0)
          //             : BorderSide.none,
          //       ),
          //       focusedBorder: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(9.51),
          //         borderSide: hasError
          //             ? const BorderSide(color: Colors.red, width: 2.0)
          //             : const BorderSide(color: Color(0xFFECF0F6)),
          //       ),
          //       filled: true,
          //       fillColor: const Color(0xFFECF0F6),
          //     ),
          //     hint: Text(
          //       "Please select your city",
          //       style: TextStyleService.getDmSans(
          //         fontSize: 16,
          //         fontWeight: FontWeight.w200,
          //         color: Color(0xFF000000),
          //       ),
          //     ),
          //   )
          if (key == 'phone')
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // เฉพาะตัวเลข
                LengthLimitingTextInputFormatter(
                    15), // จำกัดจำนวนตัวเลขที่กรอกได้ 15 ตัว
              ],
              obscureText: (isPassword && !_isPasswordVisible) ||
                  (isConfirmPassword && !_isConfirmPasswordVisible),
              style: TextStyleService.getDmSans(
                fontSize: 16,
                fontWeight: FontWeight.w200,
                color: Color(0xFF000000),
              ),
              decoration: InputDecoration(
                hintText: "Enter your phone number",
                hintStyle: TextStyleService.getDmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w200,
                  color: Color(0xFF000000),
                ),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9.51),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 2.0)
                      : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9.51),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 2.0)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9.51),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 2.0)
                      : const BorderSide(color: Color(0xFFECF0F6)),
                ),
                filled: true,
                fillColor: const Color(0xFFECF0F6),
              ),
            )
          else
            TextField(
              controller: controller,
              obscureText: (isPassword && !_isPasswordVisible) ||
                  (isConfirmPassword && !_isConfirmPasswordVisible),
              style: TextStyleService.getDmSans(
                fontSize: 16,
                fontWeight: FontWeight.w200,
                color: Color(0xFF000000),
              ),
              decoration: InputDecoration(
                hintText: label.toLowerCase().contains('email')
                    ? "Enter your email (Ex. example@gmail.com)"
                    : "Enter your ${label.split('*')[0].toLowerCase()}",
                hintStyle: TextStyleService.getDmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w200,
                  color: Color(0xFF000000),
                ),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9.51),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 2.0)
                      : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9.51),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 2.0)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9.51),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 2.0)
                      : const BorderSide(color: Color(0xFFECF0F6)),
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
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                _errors[key]!,
                style: TextStyleService.getDmSans(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequirement(bool isValid, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
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
