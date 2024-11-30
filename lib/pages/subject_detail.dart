import 'package:edugo/pages/provider_add.dart';
import 'package:edugo/pages/provider_management.dart';
import 'package:edugo/pages/subject_manage.dart';
import 'package:edugo/services/datetime_provider_add.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final double coverHeight = 227;
  final double pictureHeight = 114;

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

  void confirmDelete(BuildContext context) {
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
                width: 169,
                height: 151,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this post?',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${title ?? "porst"}"', // แสดงชื่อของทุน
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF64738B),
                ),
              ),
            ],
          ),
          actions: [
            // ปุ่ม Cancel
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  0, 34, 0, 0), // ระยะห่าง ซ้าย-บน-ขวา-ล่าง
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
                        await submitDeleteData(); // ดำเนินการลบข้อมูล
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

  Future<void> submitDeleteData() async {
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
    final top = coverHeight - pictureHeight / 2;

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
                      margin: EdgeInsets.only(bottom: pictureHeight * 2.5),
                      color: const Color(0xFF355FFF),
                      height: coverHeight,
                      padding: const EdgeInsets.only(
                        top: 58.0,
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
                              GestureDetector(
                                onTap: () {
                                  confirmDelete(context);
                                  //submitDeleteData(); // ไม่ต้องมี Navigator.pop ตรงนี้
                                },
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFED4B9E),
                                  child: Image.asset(
                                    'assets/images/icon_delete.png',
                                    width: 20.0,
                                    height: 20.0,
                                    colorBlendMode: BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              title ?? "Scholarship",
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                              maxLines:
                                  1, // Add this line to limit the text to 1 line
                              overflow: TextOverflow
                                  .ellipsis, // Optional: Handles text overflow with ellipsis if the text is too long
                            ),
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      top: top,
                      child: Center(
                        child: image != null ||
                                image != "assets/images/scholarship_program.png"
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  image ?? '',
                                  width: 245,
                                  height: 338,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/scholarship_program.png',
                                      width: 245,
                                      height: 338,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/scholarship_program.png',
                                  width: 245,
                                  height: 338,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 22),

                // Details Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scholarship Name
                      Text(
                        'Scholarship Name*',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 11),
                        child: Text(
                          title ?? "No title available.",
                          maxLines: 1, // จำกัดให้แสดงเพียง 1 บรรทัด
                          overflow: TextOverflow
                              .ellipsis, // แสดง "..." หากข้อความยาวเกิน
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64738B),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description
                      Container(
                        height: 414,
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xFFCBD5E0),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description*',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // TextField
                            Container(
                              height:
                                  353, // Adjust this height to fit your design
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFFCBD5E0),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  description ?? 'Not Specified',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF64738B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 113,
            // color: const Color.fromRGBO(104, 197, 123, 1),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 15.0, left: 16.0, right: 16.0),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Prepare data to pass
                      final existingData = {
                        'id': id,
                        'title': title,
                        'description': description,
                        'image': image,
                        'published_date': selectedStartDate?.toIso8601String(),
                      };

                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ProviderAddEdit(
                                      isEdit: true, initialData: existingData),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF355FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Edit Post",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/images/add_new_scholarship.png',
                          width: 21.0,
                          height: 21.0,
                        ),
                      ],
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
