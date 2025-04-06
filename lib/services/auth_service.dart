import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../shared/utils/jwt_helper.dart';
import 'package:edugo/config/api_config.dart';

class AuthService {
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
}
