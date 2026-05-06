import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/home_shell_screen.dart';

class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgot = '/forgot';
  static const String home = '/home';
  static const String chat = '/chat';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signup:
        return MaterialPageRoute<void>(builder: (_) => const SignupScreen());
      case forgot:
        return MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen());
      case home:
        return MaterialPageRoute<void>(builder: (_) => const HomeShellScreen());
      case chat:
        final String chatId = settings.arguments as String? ?? '';
        return MaterialPageRoute<void>(builder: (_) => ChatScreen(chatId: chatId));
      case login:
      default:
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
    }
  }
}
