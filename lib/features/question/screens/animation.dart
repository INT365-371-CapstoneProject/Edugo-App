import 'dart:convert';

import 'package:edugo/config/api_config.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

class AnimationQuestion extends StatefulWidget {
  final List<int> selectedCountries; // ใช้ int แทน String
  final String? selectedEducation;

  const AnimationQuestion({
    super.key,
    required this.selectedCountries,
    required this.selectedEducation,
  });

  @override
  State<AnimationQuestion> createState() => _AnimationQuestionState();
}

class _AnimationQuestionState extends State<AnimationQuestion>
    with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService(navigatorKey: navigatorKey);
  double _opacity = 0.0;
  Offset _offset = const Offset(0, 0.5); // เริ่มต้นเลื่อนจากด้านล่างขึ้น

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _opacity = 1.0;
        _offset = Offset.zero; // กลับไปที่ตำแหน่งปกติ
      });
    });
  }

  Future<void> SentAnswer() async {
    final url = Uri.parse(ApiConfig.answerUrl);
    String? token = await authService.getToken();
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'education_Level': widget.selectedEducation,
          'countries': widget.selectedCountries,
          'categories': [1],
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
      } else {}
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 47, 40, 255),
      body: Column(
        children: [
          // Logo with slide-in and fade-in animation
          Padding(
            padding: const EdgeInsets.only(top: 67),
            child: AnimatedSlide(
              offset: _offset,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack, // เพิ่มความเด้งแบบ bounce เล็กน้อย
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 800),
                // curve: Curves.easeOut,
                child: SvgPicture.asset(
                  'assets/images/logoQuestion.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Animated Text with fade-in
          AnimatedSlide(
            offset: _offset,
            duration: const Duration(milliseconds: 800),
            // curve: Curves.easeOutBack, // เพิ่มความเด้งแบบ bounce เล็กน้อย
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 800),
              // curve: Curves.easeOut,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  "Discover valuable educational information \nand opportunities. "
                  "Register for access to\n reliable scholarships and resources. "
                  "Join \nour community to uncover new knowledge \nand opportunities!",
                  textAlign: TextAlign.center,
                  style: TextStyleService.getDmSans(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            // Earth with slide-in and fade-in animation
            child: AnimatedSlide(
              offset: _offset,
              duration: const Duration(milliseconds: 800),
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                child: SvgPicture.asset(
                  'assets/images/earth_with_people.svg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            height: 78,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await SentAnswer();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreenApp()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 44, 33, 243),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Text(
                  "Let’s Started!",
                  style: TextStyleService.getDmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
