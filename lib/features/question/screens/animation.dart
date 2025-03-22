import 'dart:convert';

import 'package:edugo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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

class _AnimationQuestionState extends State<AnimationQuestion> {
  final AuthService authService = AuthService();

  Future<void> SentAnswer() async {
    final url = Uri.parse('https://capstone24.sit.kmutt.ac.th/un2/api/answer');

    String? token = await authService.getToken();

    // Create headers map
    Map<String, String> headers = {'Content-Type': 'application/json'};

    // Add Authorization header if token is available
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.post(
        url,
        headers: headers, // Use the headers with the token
        body: json.encode({
          'education_Level': widget.selectedEducation,
          'countries': widget.selectedCountries,
          'categories': [1],
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Success");
      } else {
        print(response);
      }
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
          // โลโก้และชื่อแอป
          Padding(
            padding: const EdgeInsets.only(top: 67),
            child: SvgPicture.asset(
              'assets/images/logoQuestion.svg',
              fit: BoxFit.cover,
            ),
          ),

          // คำอธิบาย
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              "Discover valuable educational information \nand opportunities. "
              "Register for access to\n reliable scholarships and resources. "
              "Join \nour community to uncover new knowledge \nand opportunities!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),

          // รูป Earth เต็มจอ
          Expanded(
            child: SvgPicture.asset(
              'assets/images/earth.svg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover, // ปรับให้เต็มพื้นที่
            ),
          ),

          // ปุ่ม Next
          Container(
            width: double.infinity,
            height: 78,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  SentAnswer();
                  print("Selected Countries: ${widget.selectedCountries}");
                  print("Selected Education: ${widget.selectedEducation}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 44, 33, 243),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: const Text(
                  "Let’s Started!",
                  style: TextStyle(
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
