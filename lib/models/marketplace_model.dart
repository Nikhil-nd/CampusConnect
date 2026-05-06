import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceModel {
  final String id;
  final String title;
  final double price;
  final String image;
  final String sellerId;
  final String category;
  final String description;
  final String location;
  final String contactInfo;
  final String status;
  final DateTime createdAt;

  const MarketplaceModel({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.sellerId,
    required this.category,
    required this.description,
    required this.location,
    required this.contactInfo,
    required this.status,
    required this.createdAt,
  });

  factory MarketplaceModel.fromMap(Map<String, dynamic> map, String id) {
    return MarketplaceModel(
      id: id,
      title: map['title'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      image: map['image'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      contactInfo: map['contactInfo'] as String? ?? '',
      status: map['status'] as String? ?? 'available',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'price': price,
      'image': image,
      'sellerId': sellerId,
      'category': category,
      'description': description,
      'location': location,
      'contactInfo': contactInfo,
      'status': status,
      'type': 'marketplace',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
