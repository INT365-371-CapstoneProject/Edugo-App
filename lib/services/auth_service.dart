import 'package:shared_preferences/shared_preferences.dart';
import '../shared/utils/jwt_helper.dart';

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

  // ตรวจสอบว่า Token หมดอายุหรือไม่
  bool isTokenValid(String token) {
    return !JwtHelper.isExpired(token);
  }
}
