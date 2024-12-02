import 'package:edugo/pages/provider_management.dart';
import 'package:edugo/pages/provider_profile.dart';
import 'package:edugo/pages/subject_add_edit.dart';
import 'package:edugo/pages/subject_manage.dart';
import 'package:flutter/cupertino.dart';
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

class FooterNav extends StatefulWidget {
  final String pageName;

  const FooterNav({
    super.key,
    required this.pageName,
  });

  @override
  State<FooterNav> createState() => _FooterNavState();
}

class _FooterNavState extends State<FooterNav> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 33.0,
            right: 33.0,
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Position elements with space between
              children: [
                // ปุ่ม home อยู่ทางซ้าย
                SizedBox(
                  height: 27.2,
                  width: 26.2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const ProviderManagement(),
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
                      backgroundColor: Colors.white, // สีพื้นหลังขาว
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                      side: BorderSide.none, // ไม่มีขอบ
                      elevation: 0, // ไม่ให้เงาปุ่ม
                    ),
                    child: Image.asset(
                      'assets/images/home_icon.png', // รูปภาพ fallback
                      fit: BoxFit.cover,
                      color: Color(0xFF000000),
                      width: double.infinity,
                      height: 200,
                    ),
                  ),
                ),
                // ปุ่ม search อยู่ระหว่าง home และ +
                SizedBox(
                  height: 27.2,
                  width: 26.2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Action สำหรับปุ่ม search
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // สีพื้นหลังขาว
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                      side: BorderSide.none, // ไม่มีขอบ
                      elevation: 0, // ไม่ให้เงาปุ่ม
                    ),
                    child: SvgPicture.asset(
                      'assets/images/search.svg', // ไฟล์ SVG
                      fit: BoxFit.cover,
                      color: Color(0xff000000), // ถ้าต้องการเปลี่ยนสี SVG
                      width: double.infinity,
                      height: 200,
                    ),
                  ),
                ),
                // ปุ่ม + อยู่ตรงกลาง
                SizedBox(
                  height: 32,
                  width: 64, // กำหนดความกว้างของปุ่ม
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SubjectAddEdit(isEdit: false),
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
                      backgroundColor: const Color(0xFF355FFF), // สีพื้นหลังฟ้า
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24), // มุมโค้ง
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0, // ไม่ให้เงาปุ่ม
                    ),
                    child: Icon(
                      Icons.add, // ไอคอน +
                      color: Color(0xFFDAFB59),
                      size: 28, // ขนาดไอคอน
                    ),
                  ),
                ),
                // ปุ่ม community อยู่ระหว่าง + และ profile
                SizedBox(
                  height: 27.2,
                  width: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SubjectManagement(),
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
                      backgroundColor: Colors.white, // สีพื้นหลังขาว
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                      side: BorderSide.none, // ไม่มีขอบ
                      elevation: 0, // ไม่ให้เงาปุ่ม
                    ),
                    child: Image.asset(
                      'assets/images/community_icon.png', // รูปภาพ fallback
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      color: widget.pageName == 'subject'
                          ? Color(0xffD992FA)
                          : Color(0xff000000),
                    ),
                  ),
                ),
                // ปุ่ม profile อยู่ทางขวา
                SizedBox(
                  height: 24,
                  width: 24,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // สีพื้นหลังขาว
                      shape: CircleBorder(),
                      padding: EdgeInsets.zero,
                      side: BorderSide.none, // ไม่มีขอบ
                      elevation: 0, // ไม่ให้เงาปุ่ม
                    ),
                    child: Image.asset(
                      'assets/images/profile_icon.png', // รูปภาพ fallback
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,

                      color: widget.pageName == 'profile'
                          ? Color(0xffD992FA)
                          : Color(0xff000000),
                    ),
                  ),
                )
              ]),
        ),
      ),
    );
  }
}
