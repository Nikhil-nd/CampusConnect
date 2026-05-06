import 'package:firebase_auth/firebase_auth.dart';

String firebaseErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-email-domain':
        return error.message ?? 'Use an allowed college email address.';
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Try logging in.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your connection and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'network-request-failed':
      case 'unavailable':
      case 'deadline-exceeded':
        return 'No internet connection. Check your connection and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  return 'Something went wrong. Please try again.';
}

String authErrorMessage(Object error) => firebaseErrorMessage(error);