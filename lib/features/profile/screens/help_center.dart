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

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final AuthService authService = AuthService(navigatorKey: navigatorKey);

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
                  "Help Center",
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
              "Customer Support",
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
              "If you have any questions or encounter any issues while using the system, you can contact our Customer Support during business hours through the following 2 channels:",
              style: TextStyleService.getDmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A2B8)),
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 23.0), // เพิ่ม padding
            child: Text(
              "E-mail: adminedugo@gmail.com",
              style: TextStyleService.getDmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000)),
            ),
          ),
          SizedBox(height: 40),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 23.0), // เพิ่ม padding
            child: Text(
              "If you have any questions or encounter any issues while using the system, you can contact our Customer Support during business hours through the following 2 channels:",
              style: TextStyleService.getDmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A2B8)),
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 23.0), // เพิ่ม padding
            child: Text(
              "Call Center: 012-3456789",
              style: TextStyleService.getDmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000)),
            ),
          ),
        ],
      ),
    );
  }
}
