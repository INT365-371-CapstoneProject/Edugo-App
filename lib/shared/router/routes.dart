import 'package:flutter/material.dart';
import '../../features/login&register/login.dart';
import '../../features/profile/screens/profile.dart';

class AppRoutes {
  static const String login = '/login';
  static const String scholarship = '/scholarship';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const Login(),
    scholarship: (context) => const ProviderProfile(),
  };
}
