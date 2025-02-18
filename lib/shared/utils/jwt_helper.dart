import 'package:jwt_decoder/jwt_decoder.dart';

class JwtHelper {
  // ตรวจสอบ Token หมดอายุหรือไม่
  static bool isExpired(String token) {
    return JwtDecoder.isExpired(token);
  }

  // ดึงข้อมูลจาก Payload ของ Token
  static Map<String, dynamic> decode(String token) {
    return JwtDecoder.decode(token);
  }
}
