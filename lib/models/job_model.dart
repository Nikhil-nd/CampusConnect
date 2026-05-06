import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String desc;
  final String pay;
  final String postedBy;
  final bool isFreelance;
  final String applyUrl;
  final String contactInfo;
  final DateTime createdAt;

  const JobModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.pay,
    required this.postedBy,
    required this.isFreelance,
    required this.applyUrl,
    required this.contactInfo,
    required this.createdAt,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      id: id,
      title: map['title'] as String? ?? '',
      desc: map['desc'] as String? ?? '',
      pay: map['pay'] as String? ?? '',
      postedBy: map['postedBy'] as String? ?? '',
      isFreelance: map['isFreelance'] as bool? ?? false,
      applyUrl: map['applyUrl'] as String? ?? '',
      contactInfo: map['contactInfo'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'desc': desc,
      'pay': pay,
      'postedBy': postedBy,
      'isFreelance': isFreelance,
      'applyUrl': applyUrl,
      'contactInfo': contactInfo,
      'type': 'job',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
