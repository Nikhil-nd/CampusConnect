import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/validators.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithCollegeEmail({
    required String email,
    required String password,
  }) async {
    if (!Validators.isCollegeEmailInDomains(email, AppConstants.allowedCollegeEmailDomains)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Use one of: ${AppConstants.allowedCollegeEmailDomains.map((String d) => '@$d').join(', ')}',
      );
    }

    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> forgotPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> resendVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> signOut() => _auth.signOut();
}
