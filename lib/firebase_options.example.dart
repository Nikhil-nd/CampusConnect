import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Template only.
///
/// Do NOT commit real Firebase keys/config to GitHub.
/// Generate your real file with `flutterfire configure` and keep it local.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'WEB_API_KEY',
    appId: 'WEB_APP_ID',
    messagingSenderId: 'SENDER_ID',
    projectId: 'PROJECT_ID',
    authDomain: 'PROJECT_ID.firebaseapp.com',
    storageBucket: 'PROJECT_ID.appspot.com',
    measurementId: 'MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'ANDROID_API_KEY',
    appId: 'ANDROID_APP_ID',
    messagingSenderId: 'SENDER_ID',
    projectId: 'PROJECT_ID',
    storageBucket: 'PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'IOS_API_KEY',
    appId: 'IOS_APP_ID',
    messagingSenderId: 'SENDER_ID',
    projectId: 'PROJECT_ID',
    storageBucket: 'PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'MACOS_API_KEY',
    appId: 'MACOS_APP_ID',
    messagingSenderId: 'SENDER_ID',
    projectId: 'PROJECT_ID',
    storageBucket: 'PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'WINDOWS_API_KEY',
    appId: 'WINDOWS_APP_ID',
    messagingSenderId: 'SENDER_ID',
    projectId: 'PROJECT_ID',
    authDomain: 'PROJECT_ID.firebaseapp.com',
    storageBucket: 'PROJECT_ID.appspot.com',
    measurementId: 'MEASUREMENT_ID',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'LINUX_API_KEY',
    appId: 'LINUX_APP_ID',
    messagingSenderId: 'SENDER_ID',
    projectId: 'PROJECT_ID',
    storageBucket: 'PROJECT_ID.appspot.com',
  );
}
