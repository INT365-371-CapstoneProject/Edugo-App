import 'dart:io';
import 'dart:typed_data';
import 'package:edugo/config/api_config.dart';
import 'package:edugo/shared/utils/loading.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:image_picker/image_picker.dart';

class PersonalProfileEdit extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const PersonalProfileEdit({super.key, required this.profileData});

  @override
  State<PersonalProfileEdit> createState() => _PersonalProfileEditState();
}

final double coverHeight = 152;
final double profileHeight = 90;
final _formKey = GlobalKey<FormState>();
bool isFormValid = true;

class _PersonalProfileEditState extends State<PersonalProfileEdit> {
  // แก้ไขการสร้าง AuthService instance
  final AuthService authService = AuthService(navigatorKey: navigatorKey);
  final top = coverHeight - profileHeight / 2;
  final bottom = profileHeight / 1.5;
  final arrow = const Icon(Icons.arrow_forward_ios, size: 15);

  // เพิ่มตัวแปรสำหรับเก็บสถานะการแก้ไขของ Company และ Personal
  bool isEditing = false;
  Uint8List? imageData;

  List<String> countries = [];
  String? selectedCountry;

  // Map to hold FocusNodes for each text field
  final Map<String, FocusNode> _focusNodes = {};
  // Track the currently focused field name
  String? _currentlyFocusedField;

  String? validateField(String fieldName, String? value) {
    if (value == null || value.isEmpty) {
      if (fieldName == 'phone' ||
          fieldName == 'phone_person' ||
          fieldName == 'postal_code' ||
          fieldName == 'city' ||
          fieldName == 'address') {
        return null; // อนุญาตให้ว่างได้
      }
      return 'This field is required';
    }

    switch (fieldName) {
      case 'first_name':
      case 'last_name':
        if (!RegExp(r'^[a-zA-Z]{5,20}$').hasMatch(value)) {
          return 'Must be between 5 to 20 characters';
        }
        break;
      case 'email':
        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(value)) {
          return 'Enter a valid email address';
        }
        break;
      case 'phone':
      case 'phone_person':
        if (value.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
          return 'Phone number must be exactly 10 digits';
        }
        break;
      case 'company_name':
        if (!RegExp(r'^[a-zA-Z0-9 ]{5,50}$').hasMatch(value)) {
          return 'Must be between 5 to 50 English letters, numbers, or spaces';
        }
        break;
    }

    return null;
  }

  void validateForm() {
    bool isValid = true;

    if (widget.profileData['role'] == "provider") {
      companyControllers.forEach((key, controller) {
        if (validateField(key, controller.text) != null) {
          isValid = false;
        }
      });
    }

    personalControllers.forEach((key, controller) {
      if (validateField(key, controller.text) != null) {
        isValid = false;
      }
    });

    setState(() {
      isFormValid = isValid;
    });
  }

  // สร้าง controller แยกสำหรับ Company และ Personal
  late Map<String, TextEditingController> companyControllers;
  late Map<String, TextEditingController> personalControllers;

  @override
  void initState() {
    super.initState();
    fetchCountryData();
    fetchAvatarImage();
    // สร้าง controller สำหรับแต่ละฟิลด์ใน Company และ Personal
    companyControllers = {
      'company_name':
          TextEditingController(text: widget.profileData['company_name']),
      'username': TextEditingController(text: widget.profileData['username']),
      'address': TextEditingController(
          text: widget.profileData['address']), // เปลี่ยนเป็น 'address'
      'city': TextEditingController(text: widget.profileData['city']),
      'country': TextEditingController(text: widget.profileData['country']),
      'phone': TextEditingController(text: widget.profileData['phone']),
      'postal_code':
          TextEditingController(text: widget.profileData['postal_code']),
    };

    personalControllers = {
      'first_name':
          TextEditingController(text: widget.profileData['first_name']),
      'last_name': TextEditingController(text: widget.profileData['last_name']),
      'role': TextEditingController(text: widget.profileData['role']),
      'email': TextEditingController(text: widget.profileData['email']),
      'phone_person':
          TextEditingController(text: widget.profileData['phone_person']),
    };

    // Initialize FocusNodes and add listeners
    final allControllers = {...companyControllers, ...personalControllers};
    allControllers.forEach((fieldName, controller) {
      // Skip non-editable fields like 'role' if necessary
      if (fieldName != 'role' && fieldName != 'country') {
        final focusNode = FocusNode();
        focusNode.addListener(() {
          setState(() {
            if (focusNode.hasFocus) {
              _currentlyFocusedField = fieldName;
            } else if (_currentlyFocusedField == fieldName) {
              // Clear focus only if this specific field lost focus
              _currentlyFocusedField = null;
            }
          });
        });
        _focusNodes[fieldName] = focusNode;
      }
    });
  }

  Future<void> fetchCountryData() async {
    String? token = await authService.getToken();

    final response = await http.get(
      Uri.parse(ApiConfig.countryUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> countryData = json.decode(response.body);

      setState(() {
        countries = countryData
            .map<String>((country) => country['country_name'].toString())
            .toList();
      });
    } else {
      throw Exception('Failed to load country data');
    }
  }

  Future<void> fetchAvatarImage() async {
    String? token = await authService.getToken();

    final response = await http.get(
      Uri.parse(ApiConfig.profileAvatarUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        imageData = response.bodyBytes; // แปลง response เป็น Uint8List
      });
    } else {
      throw Exception('Failed to load country data');
    }
  }

  File? _imageFile;

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Call updateAvatar() after picking the image
      // await updateAvatar(_imageFile!);
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    String? token = await authService.getToken(); // Fetch token

    var request = http.MultipartRequest(
      'PUT',
      Uri.parse(ApiConfig.profileUrl),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath(
        'avatar', imageFile.path,
        contentType: MediaType('image', 'jpeg')));

    var response = await request.send();

    if (response.statusCode == 200) {
      fetchAvatarImage();
    } else {
      throw Exception('Failed to update avatar');
    }
  }

  void _showSuccessDialogAndNavigate() {
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
                    "Edited Successful",
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "I hope you have a good feel",
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
      }
    });
  }

  Future<void> editProfile() async {
    _showCustomLoadingDialog(context);
    String? token = await authService.getToken();

    // สร้างข้อมูลโปรไฟล์ที่แก้ไขแล้ว
    Map<String, dynamic> updatedProfile = {
      "company_name": companyControllers['company_name']?.text,
      "username": companyControllers['username']?.text,
      "address": companyControllers['address']?.text,
      "city": companyControllers['city']?.text,
      "country": companyControllers['country']?.text,
      "phone": companyControllers['phone']?.text,
      "postal_code": companyControllers['postal_code']?.text,
      "first_name": personalControllers['first_name']?.text,
      "last_name": personalControllers['last_name']?.text,
      "role": personalControllers['role']?.text,
      "email": personalControllers['email']?.text,
      "phone_person": personalControllers['phone_person']?.text,
    };

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.profileUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedProfile), // ส่งข้อมูลเป็น JSON
      );

      if (mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
      }

      if (response.statusCode == 200) {
        // อัปเดตข้อมูลใน UI หลังจากแก้ไขสำเร็จ
        _showSuccessDialogAndNavigate();
        setState(() {
          widget.profileData.addAll(updatedProfile);
          isEditing = false;
        });
      } else {
        _showErrorDialog("Edited Failed", "Please, Try again.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    // ปิดการใช้งาน controller เมื่อไม่ใช้
    companyControllers.forEach((key, controller) {
      controller.dispose();
    });
    personalControllers.forEach((key, controller) {
      controller.dispose();
    });
    // Dispose FocusNodes
    _focusNodes.forEach((key, node) {
      node.removeListener(() {}); // Remove listener first
      node.dispose();
    });
    super.dispose();
  }

  String _formatValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return "-";
    }
    return value.toString();
  }

  void _resetToInitialValues() {
    setState(() {
      companyControllers.forEach((key, controller) {
        controller.text = widget.profileData[key];
      });
      personalControllers.forEach((key, controller) {
        controller.text = widget.profileData[key];
      });
    });
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
                    "We're editing your infomation",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (widget.profileData['role'] == 'provider') ...[
                    _buildSection(
                        "Company Information",
                        [
                          _buildProfileRow(
                              "Company Name:", 'company_name', isEditing),
                          _buildProfileRow("Address:", 'address', isEditing),
                          _buildProfileRow("City:", 'city', isEditing),
                          _buildProfileRow("Country:", 'country', isEditing),
                          _buildProfileRow("Phone:", 'phone', isEditing),
                          _buildProfileRow(
                              "Postal Code:", 'postal_code', isEditing),
                        ],
                        isEditing, () {
                      setState(() {
                        isEditing = !isEditing;
                      });
                    }),
                    SizedBox(height: 20),
                    Container(
                        padding: const EdgeInsets.only(bottom: 0.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFCBD5E0)),
                          ),
                        )),
                    SizedBox(height: 32),
                  ],
                  _buildSection(
                      "Personal Information",
                      [
                        _buildProfileRow("Username:", 'username', isEditing),
                        _buildProfileRow(
                            "First Name:", 'first_name', isEditing),
                        _buildProfileRow("Last Name:", 'last_name', isEditing),
                        if (!isEditing) ...[
                          _buildProfileRow("Role:", 'role', isEditing),
                        ],
                        _buildProfileRow("Email Address:", 'email', isEditing),
                        _buildProfileRow("Phone:", 'phone_person', isEditing),
                      ],
                      isEditing, () {
                    setState(() {
                      isEditing = !isEditing;
                    });
                  }),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Center(
            //   child: ElevatedButton(
            //     onPressed: () {
            //       pickImage();
            //     },
            //     child: Text("Edit Picture"),
            //     style: ElevatedButton.styleFrom(
            //       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: isEditing
                    ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isEditing = false;
                                  _resetToInitialValues();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4F4F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyleService.getDmSans(
                                  fontSize: 14,
                                  color: const Color(0xFFFFFFFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 24), // Add spacing between buttons
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (isEditing) {
                                  validateForm();
                                  if (isFormValid) {
                                    if (_imageFile?.path != null) {
                                      updateAvatar(_imageFile!);
                                    }
                                    editProfile();
                                  }
                                } else {
                                  isEditing;
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF355FFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Save",
                                style: TextStyleService.getDmSans(
                                  fontSize: 14,
                                  color: const Color(0xFFFFFFFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isEditing = !isEditing;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF355FFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Edit Profile",
                          style: TextStyleService.getDmSans(
                            fontSize: 14,
                            color: const Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: coverHeight,
          color: const Color(0xFF355FFF),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const PersonalProfile(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
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
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFDAFB59),
                    child: Image.asset(
                      'assets/images/back_button.png',
                      width: 20.0,
                      height: 20.0,
                      color: const Color(0xFF355FFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(top: coverHeight - profileHeight / 2),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: profileHeight,
                      height: profileHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(profileHeight / 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(profileHeight / 2),
                        child: imageData != null
                            ? Image.memory(
                                imageData!,
                                width: profileHeight,
                                height: profileHeight,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/avatar.png',
                                width: profileHeight,
                                height: profileHeight,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    if (isEditing)
                      Positioned.fill(
                        child: Material(
                          // color: Colors.black.withOpacity(0.5),
                          color: Color(0xFF000000),
                          borderRadius:
                              BorderRadius.circular(profileHeight / 2),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(profileHeight / 2),
                            onTap: pickImage,
                            child: Center(
                              child:
                                  Icon(Icons.camera_alt, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 8),
                  widget.profileData['role'] == 'provider'
                      ? Text(
                          widget.profileData['company_name'],
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            color: Color(0xFF000000),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          "${widget.profileData['first_name']} ${widget.profileData['last_name']}",
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            color: Color(0xFF000000),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),
                  Text(
                    '@${widget.profileData['username']}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Color(0xFF94A2B8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isEditing,
      VoidCallback onEditTap) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                    color: Color(0xFF355FFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 0),
              ),
              // Row(
              //   children: [
              //     if (isEditing)
              //       TextButton(
              //         onPressed: () {
              //           setState(() {
              //             _resetToInitialValues();
              //             if (title == "Company Information") {
              //               isEditing = false;
              //             } else if (title == "Personal Information") {
              //               isEditing = false;
              //             }
              //           });
              //         },
              //         child: Row(
              //           mainAxisSize:
              //               MainAxisSize.min, // ให้ Row กว้างเท่ากับเนื้อหา
              //           children: [
              //             Icon(Icons.cancel, color: Colors.black54, size: 16),
              //             SizedBox(
              //                 width:
              //                     4), // ปรับระยะห่างไอคอนกับข้อความตามต้องการ
              //             Text("Cancel",
              //                 style: TextStyleService.getDmSans(
              //                     color: Colors.black54,
              //                     fontSize: 14,
              //                     fontWeight: FontWeight.w400)),
              //           ],
              //         ),
              //       ),
              //     TextButton(
              //       onPressed: () {
              //         if (isEditing) {
              //           validateForm();
              //           if (isFormValid) {
              //             editProfile();
              //           }
              //         } else {
              //           onEditTap();
              //         }
              //       },
              //       child: Row(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           Icon(isEditing ? Icons.save : Icons.edit,
              //               color: Colors.black54, size: 16),
              //           SizedBox(width: 4),
              //           Text(isEditing ? "Save" : "Edit",
              //               style: TextStyleService.getDmSans(
              //                   color: Colors.black54,
              //                   fontSize: 14,
              //                   fontWeight: FontWeight.w400)),
              //         ],
              //       ),
              //     ),
              //   ],
              // )
            ],
          ),
          SizedBox(height: 24),
          Column(children: children),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String fieldName, bool isEditing) {
    bool isCountryField = fieldName == 'country';
    // Get the specific FocusNode for this field, if it exists
    final focusNode = _focusNodes[fieldName];

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          isEditing
              ? isCountryField
                  ? DropdownButtonFormField2<String>(
                      // ... existing dropdown code ...
                      isExpanded: true,
                      value: selectedCountry ??
                          companyControllers['country']?.text,
                      items: countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCountry = newValue;
                          companyControllers['country']?.text = newValue ?? '';
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFECF0F6),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9.51), // ขอบมน
                          borderSide: BorderSide.none, // No border needed here
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9.51),
                          borderSide: BorderSide.none, // No border needed here
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9.51),
                          borderSide: BorderSide.none, // No border needed here
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        padding: EdgeInsets.only(top: 20),
                        maxHeight: 300,
                        width: MediaQuery.of(context).size.width * 0.55,
                      ),
                    )
                  : StatefulBuilder(
                      // Keep StatefulBuilder for immediate validation feedback
                      builder: (context, setStateField) {
                        final controller =
                            companyControllers.containsKey(fieldName)
                                ? companyControllers[fieldName]
                                : personalControllers[fieldName];

                        final error =
                            validateField(fieldName, controller?.text);
                        final bool isFocused =
                            _currentlyFocusedField == fieldName;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              // Wrap TextField in Container for shadow
                              decoration: BoxDecoration(
                                color: Color(0xFFECF0F6), // Background color
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners like login
                                boxShadow:
                                    isFocused // Apply shadow based on focus and error state
                                        ? [
                                            BoxShadow(
                                              color: error != null
                                                  ? Color.fromRGBO(
                                                      237, 75, 158, 0.15)
                                                  : Color.fromRGBO(
                                                      108, 99, 255, 0.15),
                                              blurRadius: 0,
                                              spreadRadius: 6,
                                              offset: Offset(0, 0),
                                            ),
                                          ]
                                        : [], // No shadow if not focused
                              ),
                              child: TextField(
                                controller: controller,
                                focusNode: focusNode, // Assign the FocusNode
                                style: TextStyleService.getDmSans(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF000000),
                                ),
                                decoration: InputDecoration(
                                  // Remove fill color from TextField, container handles it
                                  // filled: true,
                                  // fillColor: Color(0xFFECF0F6),
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: Color(0xFF000000).withOpacity(
                                        0.5), // Match login hint style opacity
                                    fontWeight: FontWeight.w400,
                                  ),
                                  // Use InputBorder.none for default states, rely on container
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        9.51), // Keep inner radius
                                    borderSide: BorderSide
                                        .none, // No border needed here
                                  ),
                                  // Show red border only when there is an error
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9.51),
                                    borderSide: error != null
                                        ? const BorderSide(
                                            color: Colors.red,
                                            width: 1.5) // Error border
                                        : BorderSide
                                            .none, // No border otherwise
                                  ),
                                  // Show red border on focus only when there is an error
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9.51),
                                    borderSide: error != null
                                        ? const BorderSide(
                                            color: Colors.red,
                                            width: 1.5) // Error border
                                        : BorderSide
                                            .none, // No border otherwise (shadow indicates focus)
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16), // Match login padding
                                ),
                                onChanged: (value) {
                                  // Trigger validation update within the StatefulBuilder
                                  setStateField(() {});
                                  // Also trigger main state update if needed for other logic
                                  // setState(() {});
                                },
                              ),
                            ),
                            if (error != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 12, top: 4),
                                child: Text(
                                  error,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    )
              : Container(
                  // Non-editing state
                  width: double.infinity,
                  height: 50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Color(0xFFECF0F6),
                    borderRadius: BorderRadius.circular(9.51),
                  ),
                  child: Text(
                    _formatValue(
                      isCountryField
                          ? selectedCountry ??
                              companyControllers['country']?.text
                          : companyControllers.containsKey(fieldName)
                              ? companyControllers[fieldName]?.text
                              : personalControllers[fieldName]?.text,
                    ),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
