import 'package:edugo/pages/provider_add.dart';
import 'package:edugo/pages/provider_management.dart';
import 'package:edugo/pages/subject_manage.dart';
import 'package:edugo/services/datetime_provider_add.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

class SubjectDetail extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const SubjectDetail({
    Key? key,
    this.initialData,
  }) : super(key: key);

  @override
  State<SubjectDetail> createState() => _SubjectDetailState();
}

class _SubjectDetailState extends State<SubjectDetail> {
  int? id;
  String? title;
  String? description;
  String? image;
  DateTime? selectedStartDate;
  final double coverHeight = 138;
  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      final data = widget.initialData!;
      id = data['id'] ?? '';
      title = data['title'] ?? 'No Title';
      description = data['description'] ?? 'No Description';

      selectedStartDate = data['published_date'] != null
          ? DateTime.tryParse(data['published_date'])
          : null;

      image = data['image'] ?? '';
    }
  }

  void confirmDelete(BuildContext context, int? id) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้กดปิดนอกกรอบ Dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // ปรับมุมโค้ง
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/confirm_delete.png', // ไอคอนรูปคนทิ้งขยะ
                width: 275,
                height: 227,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this post?',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
          actions: [
            // ปุ่ม Cancel
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  0, 0, 0, 0), // ระยะห่าง ซ้าย-บน-ขวา-ล่าง
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // ระยะห่างระหว่างปุ่ม
                children: [
                  // ปุ่ม Cancel
                  SizedBox(
                    width: 134, // กำหนดความกว้าง
                    height: 41, // กำหนดความสูง
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // ปิด Dialog
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFFFFF),
                        backgroundColor: const Color(0xFF94A2B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // ปุ่ม Delete
                  SizedBox(
                    width: 134, // กำหนดความกว้าง
                    height: 41, // กำหนดความสูง
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop(); // ปิด Dialog
                        await submitDeleteData(id); // ดำเนินการลบข้อมูล
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5448E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> submitDeleteData(int? id) async {
    final String apiUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/subject/delete/${id}";

    var request = http.MultipartRequest('DELETE', Uri.parse(apiUrl));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectManagement(),
          ),
          (route) => false, // ลบ stack ทั้งหมด
        );
      } else {
        showError("Failed to delete data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      showError("Error occurred: $e");
    }
  }

  // Helper to show error messages
  void showError(String message) {
    // Replace with your preferred error handling method
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 0),
                      color: const Color(0xFF355FFF),
                      height: coverHeight,
                      padding: const EdgeInsets.only(
                        top: 72.0,
                        right: 16,
                        left: 16,
                        bottom: 22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
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
                                "Post",
                                style: GoogleFonts.dmSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFDAFB59),
                                child: Image.asset(
                                  'assets/images/notification.png',
                                  width: 40.0,
                                  height: 40.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // ทำให้ Column ชิดขอบบนสุด
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // กระจายเนื้อหาทั้งสองด้าน
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    child: Image.asset(
                                      'assets/images/avatar.png',
                                      width: 40.0,
                                      height: 40.0,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                                  SizedBox(
                                      width:
                                          24), // เพิ่มช่องว่างระหว่าง Avatar กับ Column
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start, // ทำให้ Text ชิดซ้าย
                                    children: [
                                      Text(
                                        "User Name",
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF111111),
                                        ),
                                      ),
                                      Text(
                                        selectedStartDate.toString(),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF94A2B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    builder: (BuildContext context) {
                                      return Container(
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Color(
                                              0xFFEBEFFF), // สีพื้นหลังของ modal
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width:
                                                  42, // Ensures the container takes up full width
                                              height:
                                                  5, // You can specify the height you want
                                              decoration: BoxDecoration(
                                                color: Color(
                                                    0xFFCBD5E0), // Set the background color to red
                                                borderRadius: BorderRadius.circular(
                                                    25), // Set the border radius to 25 for rounded corners
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            // เพิ่ม Container รอบๆ Column เพื่อกำหนดพื้นหลัง
                                            Container(
                                              color: const Color.fromARGB(
                                                  255,
                                                  240,
                                                  240,
                                                  240), // กำหนดสีพื้นหลังที่นี่
                                              child: Column(
                                                children: [
                                                  // ListTile สำหรับ Edit
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .white, // พื้นหลังของแต่ละรายการ
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft: Radius.circular(
                                                            12), // มุมบนซ้าย
                                                        topRight:
                                                            Radius.circular(
                                                                12), // มุมบนขวา
                                                      ),
                                                    ),
                                                    child: ListTile(
                                                      leading: SvgPicture.asset(
                                                        'assets/images/edit_svg.svg', // ไฟล์ SVG
                                                        fit: BoxFit.cover,
                                                        color: const Color(
                                                            0xff355FFF), // สีของไอคอน
                                                      ),
                                                      title: Text(
                                                        'Edit post',
                                                        style:
                                                            GoogleFonts.dmSans(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color:
                                                              Color(0xFF000000),
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        print('Edit selected');
                                                        // เพิ่มฟังก์ชัน Edit ที่นี่
                                                      },
                                                    ),
                                                  ),

                                                  // ListTile สำหรับ Delete
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .white, // พื้นหลังของแต่ละรายการ
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                                12), // มุมบนซ้าย
                                                        bottomRight:
                                                            Radius.circular(
                                                                12), // มุมบนขวา
                                                      ),
                                                    ),
                                                    child: ListTile(
                                                      leading: SvgPicture.asset(
                                                        'assets/images/delete_svg.svg', // ไฟล์ SVG
                                                        fit: BoxFit.cover,
                                                        color: const Color(
                                                            0xffED4B9E), // สีของไอคอน
                                                      ),
                                                      title: Text(
                                                        'Delete post',
                                                        style:
                                                            GoogleFonts.dmSans(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color:
                                                              Color(0xFF000000),
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        confirmDelete(
                                                            context, id);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: SvgPicture.asset(
                                  'assets/images/dot.svg', // ไฟล์ SVG
                                  fit: BoxFit.cover,
                                  color: const Color(0xff94A2B8), // สีของไอคอน
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            description.toString(),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (image!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.network(
                                  image.toString(),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/scholarship_program.png', // รูปภาพ fallback
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 200,
                                    );
                                  },
                                ),
                              ),
                            ),
                          // else
                          //   ClipRRect(
                          //     borderRadius:
                          //         BorderRadius.circular(8.0),
                          //     child: Image.asset(
                          //       'assets/images/scholarship_program.png', // รูปภาพ fallback
                          //       fit: BoxFit.cover,
                          //       width: double.infinity,
                          //       height: 200,
                          //     ),
                          //   ),
                          SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 88,
            // color: const Color.fromRGBO(104, 197, 123, 1),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 15.0, left: 16.0, right: 16.0),
                child: Container(
                  width: double
                      .infinity, // Ensures the container takes up full width
                  height: 40, // You can specify the height you want
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F0F0), // Set the background color to red
                    borderRadius: BorderRadius.circular(
                        25), // Set the border radius to 25 for rounded corners
                  ),
                  child: Align(
                    alignment:
                        Alignment.centerLeft, // Align the text to the left
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical:
                              6), // Optional padding for some space from the left
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/avatar.png',
                            width: 27.0,
                            height: 27.0,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'What about your opinion ?',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF747474),
                                fontWeight: FontWeight.w200),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
