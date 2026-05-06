import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campusconnect/services/auth_service.dart';
import 'package:campusconnect/services/firestore_service.dart';
import 'package:campusconnect/services/notification_service.dart';
import 'package:campusconnect/screens/auth/login_screen.dart';

void main() {
  group('Login Screen Widget Tests', () {
    testWidgets('LoginScreen renders with email and password input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AuthService>(create: (_) => AuthService()),
              Provider<FirestoreService>(create: (_) => FirestoreService()),
              Provider<NotificationService>(create: (_) => NotificationService()),
            ],
            child: const LoginScreen(),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('College Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('LoginScreen renders Login button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AuthService>(create: (_) => AuthService()),
              Provider<FirestoreService>(create: (_) => FirestoreService()),
              Provider<NotificationService>(create: (_) => NotificationService()),
            ],
            child: const LoginScreen(),
          ),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('LoginScreen has Create Account and Forgot Password links', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AuthService>(create: (_) => AuthService()),
              Provider<FirestoreService>(create: (_) => FirestoreService()),
              Provider<NotificationService>(create: (_) => NotificationService()),
            ],
            child: const LoginScreen(),
          ),
        ),
      );

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });
  });
}
