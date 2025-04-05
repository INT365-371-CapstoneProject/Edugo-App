import 'dart:convert';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/shared/utils/endpoint.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginService {
  final AuthService _authService = AuthService();

  Future<String?> loginUser(String emailOrUsername, String password) async {
    final url = Uri.parse(Endpoints.login);

    bool isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailOrUsername);
    String key = isEmail ? 'email' : 'username';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          key: emailOrUsername,
          'password': password,
          'remember_me': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        await _authService.saveToken(token);
        return data['token'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> addFCMToken(String token) async {
    final url = Uri.parse(Endpoints.fcm);
    final firebaseMessaging = FirebaseMessaging.instance;
    final fCMToken = await firebaseMessaging.getToken();

    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({"fcm_token": fCMToken}),
      );
    } catch (e) {
      print('Error sending FCM token: $e');
    }
  }

  Future<http.Response?> getAnswer() async {
    final url = Uri.parse(Endpoints.answer);
    final AuthService authService = AuthService();
    String? token = await authService.getToken();

    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response; // ส่ง response กลับไปให้ _showSuccessDialog
      }
    } catch (e) {
      print("Error fetching answer: $e");
    }
    return null; // ถ้า error ให้ return null
  }
}
