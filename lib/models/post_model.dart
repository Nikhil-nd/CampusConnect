import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedPostType { event, marketplace, lostFound, job }

class FeedPost {
  final String id;
  final FeedPostType type;
  final String title;
  final String description;
  final String userId;
  final String imageUrl;
  final DateTime createdAt;

  const FeedPost({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory FeedPost.fromMap(Map<String, dynamic> map, String id) {
    return FeedPost(
      id: id,
      type: _parseType(map['type'] as String? ?? 'marketplace'),
      title: map['title'] as String? ?? '',
      description: map['desc'] as String? ?? map['description'] as String? ?? '',
      userId: map['createdBy'] as String? ?? map['sellerId'] as String? ?? map['postedBy'] as String? ?? '',
      imageUrl: map['image'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static FeedPostType _parseType(String raw) {
    switch (raw) {
      case 'event':
        return FeedPostType.event;
      case 'lost_found':
        return FeedPostType.lostFound;
      case 'job':
        return FeedPostType.job;
      default:
        return FeedPostType.marketplace;
    }
  }
}
