import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundModel {
  final String id;
  final String itemName;
  final String type;
  final String location;
  final String contact;
  final String createdBy;
  final DateTime createdAt;

  const LostFoundModel({
    required this.id,
    required this.itemName,
    required this.type,
    required this.location,
    required this.contact,
    required this.createdBy,
    required this.createdAt,
  });

  factory LostFoundModel.fromMap(Map<String, dynamic> map, String id) {
    return LostFoundModel(
      id: id,
      itemName: map['itemName'] as String? ?? '',
      type: map['type'] as String? ?? 'lost',
      location: map['location'] as String? ?? '',
      contact: map['contact'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'itemName': itemName,
      'type': type,
      'location': location,
      'contact': contact,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'desc': '$type item: $itemName at $location',
    };
  }
}
