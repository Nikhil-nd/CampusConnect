import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadMarketplaceImage(File file) async {
    final String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw StateError('User must be logged in to upload images.');
    }

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('marketplace/$uid/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadProfileImage(File file) async {
    final String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw StateError('User must be logged in to upload images.');
    }

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('profiles/$uid/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
