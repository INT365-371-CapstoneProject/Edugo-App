import 'dart:convert';

class JwtHelper {
  static bool isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      final exp = payload['exp'];
      if (exp == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      print('Error parsing JWT: $e');
      return true;
    }
  }
}
