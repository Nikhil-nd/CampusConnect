import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Owns authentication session state and exposes predictable auth transitions to the UI.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthProvider(this._authService, this._firestoreService) {
    firebaseUser = _authService.currentUser;
    _authReady = true;
    _authSubscription = _authService.authStateChanges().listen((User? user) {
      firebaseUser = user;
      _authReady = true;
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _authSubscription;
  User? firebaseUser;
  bool _authReady = false;

  bool get isReady => _authReady;

  bool get isLoggedIn => firebaseUser != null;
  bool get isEmailVerified => firebaseUser?.emailVerified ?? false;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String branch,
    required int year,
  }) async {
    final UserCredential credential = await _authService.signUpWithCollegeEmail(
      email: email,
      password: password,
    );

    try {
      await _firestoreService.upsertUserProfile(
        name: name,
        email: email,
        branch: branch,
        year: year,
      );
    } on Object {
      await credential.user?.delete();
      rethrow;
    }

    firebaseUser = credential.user;
    _authReady = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    await _authService.login(email: email, password: password);
  }

  Future<void> forgotPassword(String email) => _authService.forgotPassword(email);

  Future<void> resendVerification() => _authService.resendVerification();

  Future<void> reloadUser() async {
    await firebaseUser?.reload();
    firebaseUser = _authService.currentUser;
    _authReady = true;
    notifyListeners();
  }

  Future<void> logout() => _authService.signOut();

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
