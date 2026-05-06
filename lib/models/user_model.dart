import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String branch;
  final int year;
  final String profilePic;
  final int reputation;
  final bool isAdmin;
  final bool isBanned;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.branch,
    required this.year,
    required this.profilePic,
    required this.reputation,
    required this.isAdmin,
    required this.isBanned,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      branch: map['branch'] as String? ?? '',
      year: map['year'] as int? ?? 1,
      profilePic: map['profilePic'] as String? ?? '',
      reputation: map['reputation'] as int? ?? 0,
      isAdmin: map['isAdmin'] as bool? ?? false,
      isBanned: map['isBanned'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'branch': branch,
      'year': year,
      'profilePic': profilePic,
      'reputation': reputation,
      'isAdmin': isAdmin,
      'isBanned': isBanned,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
