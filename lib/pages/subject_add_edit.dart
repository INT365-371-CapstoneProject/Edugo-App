import 'package:edugo/pages/subject_manage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker package
import 'dart:io'; // Import to handle File objects
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class SubjectAddEdit extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  const SubjectAddEdit({
    Key? key,
    required this.isEdit,
    this.initialData,
  });

  @override
  State<SubjectAddEdit> createState() => _SubjectAddEditState();
}

class _SubjectAddEditState extends State<SubjectAddEdit> {
  int? id;
  String? description; // สำหรับ Description
  String? image;
  DateTime? selectedStartDate;
  File? _selectedImage;
  Map<String, dynamic> originalValues = {};
  Color descriptionBorderColor = Color(0xFFF8F8F8);
  String? descriptionError;
  bool isValidDescription = false;

  TextEditingController _descriptionController =
      TextEditingController(); // Controller for description text field

  // Function to pick an image using ImagePicker
  // Future<void> _pickImage() async {
  //   final ImagePicker _picker = ImagePicker();
  //   // Show a dialog or options for taking a photo or picking from the gallery
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

  //   if (image != null) {
  //     setState(() {
  //       _selectedImage = File(image.path); // Set the selected image file
  //     });
  //   }
  // }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // ตรวจสอบชนิดไฟล์ (extension)
      final String extension = image.path.split('.').last.toLowerCase();
      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
        _showErrorDialog('Image Type is JPG or PNG only');
        return;
      }

      // ตรวจสอบขนาดไฟล์ (เช่น ไม่เกิน 5MB)
      final int fileSize = await File(image.path).length();
      if (fileSize > 5 * 1024 * 1024) {
        // 5MB
        _showErrorDialog('File more than 5MB');
        return;
      }

      setState(() {
        _selectedImage = File(image.path); // เก็บไฟล์รูปที่ผ่านการตรวจสอบแล้ว
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Image Type invalid'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Ok'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.initialData != null) {
      final data = widget.initialData!;
      id = data['id'] ?? '';
      description = data['description'] ?? '';
      image = data['image'] ?? '';

      _descriptionController.text = description ?? '';
      originalValues = {
        'description': description,
        'image': image,
      };
    } else {
      // กำหนดค่าเริ่มต้นหากไม่ได้อยู่ในโหมดแก้ไข
      description = '';
    }
  }

  Future<void> submitAddData() async {
    final String apiUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/subject/add";

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    request.fields['title'] =
        "Title Subject"; // You can replace this with dynamic data
    request.fields['description'] =
        _descriptionController.text; // Get description from the text field
    request.fields['posts_type'] = 'Subject';
    request.fields['publish_date'] =
        '${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z';
    request.fields['country_id'] = '1';

    if (_selectedImage != null) {
      // ตรวจสอบนามสกุลไฟล์
      String fileExtension = _selectedImage!.path.split('.').last.toLowerCase();
      MediaType? contentType;

      if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = MediaType('image', 'jpeg');
      } else if (fileExtension == 'png') {
        contentType = MediaType('image', 'png');
      } else {
        // หากรูปภาพไม่ใช่ jpg หรือ png
        showError("Unsupported file format. Please upload a JPG or PNG image.");
        return;
      }

      // อ่านไฟล์เป็นไบต์และเพิ่มเข้าไปในคำขอ
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.$fileExtension', // ใช้นามสกุลไฟล์จริง
          contentType: contentType, // กำหนด MediaType ตามประเภทของไฟล์
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            height: 301,
            width: 298,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(249, 84, 83, 83)),
                    strokeWidth: 6.0,
                  ),
                  SizedBox(height: 40),
                  Text(
                    "Waiting for Posting",
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      // Delay for 3 seconds to simulate waiting time
      await Future.delayed(Duration(seconds: 3));

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccessDialog(context, false);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SubjectManagement(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      } else {
        showError("Failed to submit data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close the loading dialog
      showError("Error occurred: $e");
    }
  }

  Future<void> submitEditData() async {
    final String apiUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/subject/update/${id}";

    var request = http.MultipartRequest('PUT', Uri.parse(apiUrl));

    // ตรวจสอบว่าข้อมูล description เปลี่ยนไปหรือไม่
    if (_descriptionController.text != originalValues['description']) {
      request.fields['description'] = _descriptionController.text;
    }

    // ตรวจสอบว่ามีการอัปเดตรูปภาพใหม่หรือไม่
    if (_selectedImage != null) {
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else if (originalValues['image'] != null &&
        (image == null || image != originalValues['image'])) {
      // ถ้ารูปภาพต้นฉบับถูกลบ ต้องส่งคำขอให้ลบรูปภาพด้วย
      request.fields['image'] = '';
    }

    // เพิ่มฟิลด์อื่นๆ ที่จำเป็น
    request.fields['title'] =
        "Title Subject"; // คุณสามารถแทนที่ด้วยข้อมูลไดนามิก
    request.fields['posts_type'] = 'Subject';
    request.fields['publish_date'] =
        '${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z';
    request.fields['country_id'] = '1';

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            height: 301,
            width: 298,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(249, 84, 83, 83)),
                    strokeWidth: 6.0,
                  ),
                  SizedBox(height: 40),
                  Text(
                    "Waiting for Updating",
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      // Delay for 3 seconds to simulate waiting time
      await Future.delayed(Duration(seconds: 3));

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccessDialog(context, true);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SubjectManagement(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      } else {
        showError("Failed to submit data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close the loading dialog
      showError("Error occurred: $e");
    }
  }

  // Helper to show error messages
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Helper to show success messages
  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showSuccessDialog(BuildContext context, bool isEdit) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิดโดยการแตะด้านนอก
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            height: 370, // กำหนดความสูงของ Dialog
            width: 298,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/success.png',
                    height: 190,
                    width: 220, // ปรับขนาดรูปที่นี่
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isEdit ? "Update Successful" : "Post Successful!",
                    style: GoogleFonts.dmSans(
                      fontSize: 24, // ปรับขนาดฟอนต์ที่นี่
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectManagement(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF355FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(
                        color: Colors.white, // กำหนดสีข้อความเป็นสีขาว
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              height: 100,
              color: Color(0xFF355FFF),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                alignment: Alignment.center, // จัดกึ่งกลางทุกอย่างใน Stack
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // จัดปุ่มซ้าย-ขวา
                    children: [
                      SizedBox(
                        width: 40, // กำหนดความกว้าง
                        height: 40, // กำหนดความสูง
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF9C7E1), // สีพื้นหลัง
                            borderRadius:
                                BorderRadius.circular(20), // มุมโค้ง 20
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, color: Color(0xFFED4B9E)),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const SubjectManagement(),
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
                            },
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDAFB59),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            if (description == null ||
                                description!
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .isEmpty ||
                                description!
                                        .replaceAll(RegExp(r'\s+'), '')
                                        .length <
                                    10 ||
                                description!
                                        .replaceAll(RegExp(r'\s+'), '')
                                        .length >
                                    3000) {
                              descriptionError =
                                  "Minimum 10 characters, maximum 3000 characters";
                              isValidDescription = false;
                              descriptionBorderColor = Colors.red;
                            } else {
                              isValidDescription = true;
                            }
                          });

                          // เรียกใช้งานฟังก์ชันเมื่อข้อมูลถูกต้อง
                          if (isValidDescription) {
                            if (widget.isEdit) {
                              submitEditData();
                            } else {
                              submitAddData();
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Required fields"),
                                  content: Text(
                                      "Please fill in all the required fields."),
                                  actions: [
                                    TextButton(
                                      child: Text("OK"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        child: Text(
                          widget.isEdit ? "Update" : "Post",
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF355FFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Text อยู่ตรงกลาง
                  Text(
                    widget.isEdit ? "Edit Post" : "Create Post",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content Section (using Expanded to take available space)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 18.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage:
                                    AssetImage('assets/images/avatar.png'),
                              ),
                              SizedBox(width: 16),
                              Text(
                                "User Name",
                                style: GoogleFonts.dmSans(
                                    color: Color(0xFF111111),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Detail Text Input Section
                          Container(
                            decoration: BoxDecoration(
                                color: Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: descriptionBorderColor)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 12.0, right: 12),
                              child: TextField(
                                controller: _descriptionController,
                                onChanged: (value) {
                                  setState(() {
                                    description = value;
                                    if (value
                                                .replaceAll(RegExp(r'\s+'), '')
                                                .length <
                                            10 ||
                                        value
                                                .replaceAll(RegExp(r'\s+'), '')
                                                .length >
                                            3000) {
                                      descriptionBorderColor = Colors.red;
                                      descriptionError =
                                          "Minimum 10 characters, maximum 3000 characters";
                                      isValidDescription = false;
                                    } else {
                                      descriptionBorderColor =
                                          Color(0xFFCBD5E0);
                                      descriptionError = null;
                                      isValidDescription = true; // ฟอร์มถูกต้อง
                                    }
                                  });
                                }, // Allow multipl // Bind the controller here
                                decoration: InputDecoration(
                                  hintText: "What's on your mind?",
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: Color(0xFF94A2B8),
                                    fontWeight: FontWeight.w200,
                                  ),
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.multiline,
                                minLines: 3,
                                maxLines: null,
                              ),
                            ),
                          ),
                          if (descriptionError != null) // แสดงข้อความข้อผิดพลาด
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                descriptionError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          // Image Preview Section
                          if (_selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else if (widget.isEdit &&
                              image != null &&
                              image!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                    'Error loading image',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Footer Section (remains fixed at the bottom)
            GestureDetector(
              onTap:
                  _pickImage, // Trigger the image picker when footer is tapped
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/photo_icon.png',
                        width: 20.0,
                        height: 20.0,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Share Your Photo Here",
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64738B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
