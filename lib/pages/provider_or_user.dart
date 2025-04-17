import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/pages/welcome_user_page.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProviderOrUser extends StatelessWidget {
  const ProviderOrUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 87), // Space at the top
                  // Logo at the top
                  SizedBox(
                    width: 175,
                    height: 37.656,
                    child: Image.asset(
                      "assets/images/logoColor.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 50.34),
                  // Heading text
                  Text(
                    "Tell us who you are?",
                    style: TextStyleService.getDmSans(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.normal,
                      color: Color(0xFF000000),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // Description text
                  Text(
                    "Tell us a little about yourself! You can easily select your role in this app. If you're a scholarship provider, please choose 'Provider' above. However, if you're looking for educational opportunities and additional experiences, please select 'User' below.",
                    style: TextStyleService.getDmSans(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w200,
                      fontStyle: FontStyle.normal,
                      color: Color(0xFF465468),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 31.0),
              child: Column(
                children: [
                  // Button for "I'm providing scholarships"
                  _buildRoleButton(
                    context,
                    title: "I'm providing scholarships",
                    description:
                        "For scholarship providers, you can\nshare exciting and valuable\nscholarship opportunities with users\nin our app!",
                    imagePath: "assets/images/provider.svg",
                    borderColor: Color(0xFF355FFF),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const WelcomeUserPage(isProvider: true),
                        ),
                      );
                    },
                    rowPadding: const EdgeInsets.symmetric(
                        horizontal: 32.0), // กำหนด padding สำหรับ Row
                    spacingWidget:
                        const SizedBox(width: 0), // กำหนด spacing ที่แตกต่างได้
                  ),
                  const SizedBox(height: 24),
                  // Button for "I'm seeking scholarships"
                  _buildRoleButton(
                    context,
                    title: "I'm seeking scholarships",
                    description:
                        "If you're looking for reliable sources of\nknowledge and scholarship information,\nsign up now! Start exploring unlimited\nlearning opportunities today!",
                    imagePath: "assets/images/user.svg",
                    borderColor: Color(0xFF355FFF),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const WelcomeUserPage(isUser: true),
                        ),
                      );
                    },
                    rowPadding: const EdgeInsets.symmetric(
                        horizontal: 21.0), // กำหนด padding สำหรับ Row
                    spacingWidget: const SizedBox(
                        width: 19), // กำหนด spacing ที่แตกต่างได้
                  ),
                  const SizedBox(height: 30), // Add space below the last button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required String description,
    required String imagePath,
    required Color borderColor,
    required VoidCallback onTap,
    EdgeInsets? rowPadding, // เพิ่มพารามิเตอร์สำหรับ padding ของ Row
    Widget spacingWidget =
        const SizedBox(width: 0), // เพิ่มพารามิเตอร์สำหรับ spacing
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: rowPadding ??
              EdgeInsets.all(16.0), // ใช้ padding ที่ส่งมา หรือค่าเริ่มต้น
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(imagePath),
              spacingWidget, // ใช้ spacingWidget ที่ส่งเข้ามา
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyleService.getDmSans(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000000),
                        height: 1.42857, // คำนวณจาก 20px / 14px
                      ),
                    ),
                    const SizedBox(height: 4), // Reduced height from 8 to 4
                    Text(
                      description,
                      style: TextStyleService.getDmSans(
                        fontSize: 9.0, // Reduced font size from 10.0 to 9.0
                        fontWeight: FontWeight.w200,
                        color: Color(0xFF465468),
                      ),
                      maxLines: 4, // Limit lines to prevent excessive overflow
                      overflow: TextOverflow
                          .ellipsis, // Add ellipsis if it still overflows
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
