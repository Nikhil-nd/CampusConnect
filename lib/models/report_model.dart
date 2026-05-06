import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String entityType;
  final String entityId;
  final String entityTitle;
  final String reason;
  final String reportedBy;
  final DateTime createdAt;
  final bool resolved;

  const ReportModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.reason,
    required this.reportedBy,
    required this.createdAt,
    required this.resolved,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      entityTitle: map['entityTitle'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      reportedBy: map['reportedBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolved: map['resolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'entityType': entityType,
      'entityId': entityId,
      'entityTitle': entityTitle,
      'reason': reason,
      'reportedBy': reportedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolved': resolved,
    };
  }
}