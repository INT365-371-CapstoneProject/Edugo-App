import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
import 'package:edugo/shared/utils/loading.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/features/subject/subject_add_edit.dart';
import 'package:edugo/features/subject/subject_detail.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http_parser/http_parser.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

class ManageAccount extends StatefulWidget {
  final int id; // เพิ่มตัวแปร id

  const ManageAccount({super.key, required this.id});

  @override
  State<ManageAccount> createState() => _ManageAccountState();
}

class _ManageAccountState extends State<ManageAccount> {
  final AuthService authService = AuthService(navigatorKey: navigatorKey);

  void confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้กดปิดนอกกรอบ Dialog
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // ปรับมุมโค้ง
          ),
          child: Container(
            width: 300, // ปรับขนาดให้เหมาะสมกับเนื้อหา
            height: 360,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/confirm_delete.png', // ไอคอนรูปคนทิ้งขยะ
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to\ndelete your account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'All your data will be deleted\nand cannot be recovered.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A2B8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      0, 34, 0, 0), // ระยะห่าง ซ้าย-บน-ขวา-ล่าง
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // ระยะห่างระหว่างปุ่ม
                    children: [
                      SizedBox(
                        width: 120, // กำหนดความกว้าง
                        height: 45, // กำหนดความสูง
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(); // ปิด Dialog
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFFFFFF),
                            backgroundColor: const Color(0xFF94A2B8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                      SizedBox(
                        width: 120, // กำหนดความกว้าง
                        height: 45, // กำหนดความสูง
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop(); // ปิด Dialog
                            submitDeleteAccount(); // เรียกใช้ฟังก์ชันลบข้อมูล
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD5448E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
            ),
          ),
        );
      },
    );
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
                  const SizedBox(height: 10),
                  GradientFadeSpinner(),
                  const SizedBox(height: 24),
                  Text(
                    "We're deleting your account...",
                    style: TextStyleService.getDmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please wait a moment.",
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
                  const SizedBox(height: 10),
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

  void _showSuccessDialogAndNavigate(Widget page) {
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
                  const SizedBox(height: 10),
                  Image.asset(
                    "assets/images/success_check.png",
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Delete Successful",
                    textAlign: TextAlign.center,
                    style: TextStyleService.getDmSans(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We're sorry to see you go and hope to see you again",
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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = 0.0;
              const end = 1.0;
              const curve = Curves.easeOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return FadeTransition(
                  opacity: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    });
  }

  Future<void> submitDeleteAccount() async {
    final String apiUrl = "${ApiConfig.userUrl}/${widget.id}";
    String? token = await authService.getToken();

    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    var request = http.MultipartRequest('DELETE', Uri.parse(apiUrl));
    request.headers.addAll(headers);

    // แสดง Loading ก่อนเริ่มลบ
    _showCustomLoadingDialog(context);

    try {
      var response = await request.send();

      // ปิด loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        _showSuccessDialogAndNavigate(Login());
      } else {
        // แจ้ง Error เพิ่มเติมได้ที่นี่
        _showErrorDialog("Failed to delete account", "Please try again later.");
      }
    } catch (e) {
      // ปิด loading dialog กรณีเกิด error
      Navigator.of(context).pop();
      _showErrorDialog("Error deleting account", "Please try again later.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  "Manage Account",
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

          const SizedBox(height: 16.0),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 23.0), // เพิ่ม padding
            child: Text(
              "Delete Account",
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF000000),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 23.0), // เพิ่ม padding
            child: Text(
              "By deleting your account, and all associated\ndata will be removed according to our privacy\npolicy. Please note that once the deletion is\ncomplete, it cannot be recovered.",
              style: TextStyleService.getDmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A2B8)),
            ),
          )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              confirmDelete(context); // เรียกใช้ฟังก์ชันยืนยันการลบ
            },
            style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.pressed)) {
                  return const Color(0xFFD5448E); // พื้นหลังตอนกด
                }
                return Colors.white; // พื้นหลังปกติ
              }),
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.white; // สีข้อความตอนกด
                }
                return const Color(0xFFD5448E); // สีข้อความปกติ
              }),
              side: MaterialStateProperty.all(
                const BorderSide(color: Color(0xFFD5448E), width: 2),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
            ),
            child: Text(
              'Delete Account',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
