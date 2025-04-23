import 'dart:convert';
import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/login&register/login.dart'; // Import Login screen
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart'; // Import Material
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../shared/utils/jwt_helper.dart';

class AuthService {
  final GlobalKey<NavigatorState> navigatorKey;

  AuthService({required this.navigatorKey});

  // บันทึก Token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ดึง Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ลบ Token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ลบ FCM Token
  Future<void> removeFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
  }

  // ตรวจสอบว่า Token หมดอายุหรือไม่
  bool isTokenValid(String token) {
    return !JwtHelper.isExpired(token);
  }

  // ฟังก์ชันตรวจสอบความถูกต้องของ token
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // ตรวจสอบการหมดอายุของ token
      if (!isTokenValid(token)) {
        await removeToken();
        return false;
      }

      // ทดสอบเรียก API เพื่อตรวจสอบความถูกต้องของ token
      final response = await http.get(
        Uri.parse(ApiConfig.profileUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        await removeToken();
        return false;
      }

      return true;
    } catch (e) {
      print("Error validating token: $e");
      return false;
    }
  }

  // ฟังก์ชันดึงข้อมูลโปรไฟล์ (อาจจะแยกเป็น private helper)
  Future<Map<String, dynamic>?> _fetchProfileData() async {
    String? token = await getToken();
    if (token == null || JwtDecoder.isExpired(token)) {
      print("Token not found or expired for fetching profile.");
      return null;
    }

    final url = Uri.parse(ApiConfig.profileUrl);
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data.containsKey('profile') && data['profile'] is Map
            ? data['profile'] as Map<String, dynamic>
            : null;
      } else if (response.statusCode == 401) {
        // ถ้า Token ไม่ถูกต้อง (Unauthorized) ให้ถือว่า session ไม่ valid
        print("Unauthorized access during profile fetch.");
        return null; // คืนค่า null เพื่อบ่งบอกว่า session ไม่ valid
      } else {
        print(
            "Failed to load profile data during session check: ${response.statusCode}");
        // กรณี error อื่นๆ อาจจะไม่ logout ทันที แต่คืนค่า profile ไม่ได้
        return null; // หรือจัดการ error ตามความเหมาะสม
      }
    } catch (e) {
      print("Error fetching profile data during session check: $e");
      return null; // คืนค่า null เมื่อเกิด exception
    }
  }

  // ฟังก์ชันสำหรับ Logout และกลับไปหน้า Login พร้อมแสดง Dialog (ถ้ามี)
  Future<void> logoutAndRedirectToLogin(
      {String? title, String? message}) async {
    // แสดง Dialog ก่อนถ้ามี title และ message
    if (navigatorKey.currentContext != null &&
        title != null &&
        message != null) {
      await showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false, // ไม่ให้ปิด dialog โดยการแตะข้างนอก
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyleService.getDmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ), // สีส้มสำหรับ Warning
            ),
            content: Text(message, textAlign: TextAlign.center),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Dialog
                },
              ),
            ],
          );
        },
      );
    }

    // ดำเนินการ Logout และ Redirect
    await removeToken();
    await removeFCMToken();
    // ใช้ navigatorKey เพื่อเปลี่ยนหน้า และล้าง stack เก่าทั้งหมด
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false, // ลบทุก route ที่มีอยู่
    );
  }

  // ฟังก์ชันตรวจสอบสถานะ Session ล่าสุด
  Future<void> checkSessionValidity() async {
    final profileData = await _fetchProfileData();

    // ถ้า profileData เป็น null อาจจะเกิดจาก token หมดอายุ, ไม่มี token, หรือ API error
    if (profileData == null) {
      // ตรวจสอบ token อีกครั้งก่อน logout เผื่อเป็นแค่ network error ชั่วคราว
      String? token = await getToken();
      if (token == null || JwtDecoder.isExpired(token)) {
        print("Token invalid or expired during validity check. Logging out.");
        // ไม่ต้องแสดง Dialog สำหรับ token หมดอายุหรือไม่มี token
        await logoutAndRedirectToLogin();
      } else {
        print(
            "Could not fetch profile, but token seems valid. Skipping logout for now.");
        // อาจจะลองใหม่ภายหลัง หรือแจ้งเตือนผู้ใช้ว่าตรวจสอบข้อมูลไม่ได้
        // ไม่แสดง Dialog ในกรณีนี้ เพราะอาจเป็นปัญหาชั่วคราว
      }
      return;
    }

    // ตรวจสอบ Status
    final status = profileData['status'];
    if (status == 'Suspended') {
      await logoutAndRedirectToLogin(
        title: "Account Suspended",
        message: "Your account is currently suspended. Please contact support.",
      );
      return; // ออกจากการทำงานหลัง logout
    }

    // ตรวจสอบ Role และ Verify (สำหรับ Provider)
    final role = profileData['role'];
    if (role == 'provider') {
      final verify = profileData['verify'];
      if (verify == 'No') {
        await logoutAndRedirectToLogin(
          title: "Verification Required",
          message:
              "Your provider account has not been verified. Please contact support.",
        );
        return; // ออกจากการทำงานหลัง logout
      } else if (verify == 'Waiting') {
        await logoutAndRedirectToLogin(
          title: "Verification Pending",
          message:
              "Your provider account is awaiting verification. Please wait for approval.",
        );
        return; // ออกจากการทำงานหลัง logout
      }
      // ถ้า verify เป็น 'Yes' ก็ผ่าน
    }

    print("Session is valid.");
    // ถ้าผ่านหมด แสดงว่า session ยังใช้งานได้
  }
}
