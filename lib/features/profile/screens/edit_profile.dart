import 'dart:io';
import 'dart:typed_data';
import 'package:edugo/shared/utils/endpoint.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:image_picker/image_picker.dart';

class ProviderProfileEdit extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const ProviderProfileEdit({super.key, required this.profileData});

  @override
  State<ProviderProfileEdit> createState() => _ProviderProfileEditState();
}

final double coverHeight = 152;
final double profileHeight = 90;
final _formKey = GlobalKey<FormState>();
bool isFormValid = true;

class _ProviderProfileEditState extends State<ProviderProfileEdit> {
  final AuthService authService = AuthService();
  final top = coverHeight - profileHeight / 2;
  final bottom = profileHeight / 1.5;
  final arrow = const Icon(Icons.arrow_forward_ios, size: 15);

  // เพิ่มตัวแปรสำหรับเก็บสถานะการแก้ไขของ Company และ Personal
  bool isEditingCompany = false;
  bool isEditingPersonal = false;
  Uint8List? imageData;

  List<String> countries = [];
  String? selectedCountry;

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
        if (!RegExp(r'^[a-zA-Z]{2,25}$').hasMatch(value)) {
          return 'Must be between 2 to 25 English letters';
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
    print(widget.profileData);
    print(widget.profileData['address']);
    print(fetchCountryData);
    // สร้าง controller สำหรับแต่ละฟิลด์ใน Company และ Personal
    companyControllers = {
      'company_name':
          TextEditingController(text: widget.profileData['company_name']),
      'address': TextEditingController(
          text: widget.profileData['address']), // เปลี่ยนเป็น 'address'
      'city': TextEditingController(text: widget.profileData['city']),
      'country': TextEditingController(text: widget.profileData['country']),
      'phone': TextEditingController(text: widget.profileData['phone']),
      'postal_code':
          TextEditingController(text: widget.profileData['postal_code']),
    };

    print(companyControllers['address']);

    personalControllers = {
      'first_name':
          TextEditingController(text: widget.profileData['first_name']),
      'last_name': TextEditingController(text: widget.profileData['last_name']),
      'role': TextEditingController(text: widget.profileData['role']),
      'email': TextEditingController(text: widget.profileData['email']),
      'phone_person':
          TextEditingController(text: widget.profileData['phone_person']),
    };
  }

  Future<void> fetchCountryData() async {
    String? token = await authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoints.country),
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

      print(countries); // ตรวจสอบค่าที่ได้
    } else {
      throw Exception('Failed to load country data');
    }
  }

  Future<void> fetchAvatarImage() async {
    String? token = await authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoints.getProfileAvatar),
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
      await updateAvatar(_imageFile!);
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    String? token = await authService.getToken(); // Fetch token

    var request = http.MultipartRequest(
      'PUT',
      Uri.parse(Endpoints.profile),
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

  Future<void> editProfile() async {
    String? token = await authService.getToken();

    // สร้างข้อมูลโปรไฟล์ที่แก้ไขแล้ว
    Map<String, dynamic> updatedProfile = {
      "company_name": companyControllers['company_name']?.text,
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
        Uri.parse(Endpoints.profile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedProfile), // ส่งข้อมูลเป็น JSON
      );

      if (response.statusCode == 200) {
        // อัปเดตข้อมูลใน UI หลังจากแก้ไขสำเร็จ
        setState(() {
          widget.profileData.addAll(updatedProfile);
          isEditingCompany = false;
          isEditingPersonal = false;
        });
      } else {
        throw Exception('Failed to update profile. Error: ${response.body}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: bottom),
            if (widget.profileData['role'] == 'provider') ...[
              _buildSection(
                  "Company Information",
                  [
                    _buildProfileRow(
                        "Company Name:", 'company_name', isEditingCompany),
                    _buildProfileRow("Address:", 'address', isEditingCompany),
                    _buildProfileRow("City:", 'city', isEditingCompany),
                    _buildProfileRow("Country:", 'country', isEditingCompany),
                    _buildProfileRow("Phone:", 'phone', isEditingCompany),
                    _buildProfileRow(
                        "Postal Code:", 'postal_code', isEditingCompany),
                  ],
                  isEditingCompany, () {
                setState(() {
                  isEditingCompany = !isEditingCompany;
                });
              }),
            ],
            SizedBox(height: 16),
            _buildSection(
                "Personal Information",
                [
                  _buildProfileRow(
                      "First Name:", 'first_name', isEditingPersonal),
                  _buildProfileRow(
                      "Last Name:", 'last_name', isEditingPersonal),
                  if (!isEditingPersonal) ...[
                    _buildProfileRow("Role:", 'role', isEditingPersonal),
                  ],
                  _buildProfileRow(
                      "Email Address:", 'email', isEditingPersonal),
                  _buildProfileRow("Phone:", 'phone_person', isEditingPersonal),
                ],
                isEditingPersonal, () {
              setState(() {
                isEditingPersonal = !isEditingPersonal;
              });
            }),
            SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  pickImage();
                },
                child: Text("Edit Picture"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
              ),
            ),
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
                            const ProviderProfile(),
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
        Positioned(
          top: coverHeight - (profileHeight / 2),
          left: MediaQuery.of(context).size.width / 2 - (profileHeight / 2),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: profileHeight,
                    height: profileHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(profileHeight / 2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(profileHeight / 2),
                      child: imageData != null
                          ? Image.memory(imageData!)
                          : Image.asset(
                              'assets/images/welcome.png',
                              width: profileHeight,
                              height: profileHeight,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  // Positioned(
                  //   right: -4,
                  //   bottom: -4,
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       pickImage();
                  //     },
                  //     child: CircleAvatar(
                  //       radius: 16,
                  //       backgroundColor: Colors.white,
                  //       child:
                  //           Icon(Icons.edit, color: Colors.black54, size: 16),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isEditing,
      VoidCallback onEditTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (isEditing)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _resetToInitialValues();
                          if (title == "Company Information") {
                            isEditingCompany = false;
                          } else if (title == "Personal Information") {
                            isEditingPersonal = false;
                          }
                        });
                      },
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min, // ให้ Row กว้างเท่ากับเนื้อหา
                        children: [
                          Icon(Icons.cancel, color: Colors.black54, size: 16),
                          SizedBox(
                              width:
                                  4), // ปรับระยะห่างไอคอนกับข้อความตามต้องการ
                          Text("Cancel",
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 14)),
                        ],
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      if (isEditing) {
                        validateForm();
                        if (isFormValid) {
                          editProfile();
                        }
                      } else {
                        onEditTap();
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isEditing ? Icons.save : Icons.edit,
                            color: Colors.black54, size: 16),
                        SizedBox(width: 4),
                        Text(isEditing ? "Save" : "Edit",
                            style:
                                TextStyle(color: Colors.black54, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String fieldName, bool isEditing) {
    bool isCountryField = fieldName == 'country';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: 140,
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: isEditing
                ? isCountryField
                    ? DropdownButtonFormField2<String>(
                        isExpanded: true,
                        value: selectedCountry ??
                            companyControllers['country']?.text,
                        items: countries.map((String country) {
                          return DropdownMenuItem<String>(
                            value: country,
                            child:
                                Text(country, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCountry = newValue;
                            companyControllers['country']?.text =
                                newValue ?? '';
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          padding: EdgeInsets.only(top: 20),
                          maxHeight: 300,
                          width: MediaQuery.of(context).size.width * 0.55,
                        ),
                      )
                    : StatefulBuilder(
                        builder: (context, setStateField) {
                          return TextField(
                            controller:
                                companyControllers.containsKey(fieldName)
                                    ? companyControllers[fieldName]
                                    : personalControllers[fieldName],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: validateField(
                                              fieldName,
                                              companyControllers
                                                      .containsKey(fieldName)
                                                  ? companyControllers[
                                                          fieldName]
                                                      ?.text
                                                  : personalControllers[
                                                          fieldName]
                                                      ?.text) ==
                                          null
                                      ? Colors.grey
                                      : Colors.red,
                                ),
                              ),
                              errorText: validateField(
                                fieldName,
                                companyControllers.containsKey(fieldName)
                                    ? companyControllers[fieldName]?.text
                                    : personalControllers[fieldName]?.text,
                              ),
                            ),
                            onChanged: (value) {
                              setStateField(
                                  () {}); // Refresh validation on change
                            },
                          );
                        },
                      )
                : Text(
                    _formatValue(isCountryField
                        ? selectedCountry ?? companyControllers['country']?.text
                        : companyControllers.containsKey(fieldName)
                            ? companyControllers[fieldName]?.text
                            : personalControllers[fieldName]?.text),
                    style:
                        GoogleFonts.dmSans(fontSize: 16, color: Colors.black87),
                  ),
          ),
        ],
      ),
    );
  }
}
