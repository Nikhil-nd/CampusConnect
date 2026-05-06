import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String desc;
  final DateTime date;
  final String organizer;
  final String organizerId;
  final String location;
  final bool isHackathon;
  final String applyUrl;
  final String contactInfo;
  final bool approved;
  final List<String> registeredUsers;

  const EventModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.date,
    required this.organizer,
    required this.organizerId,
    required this.location,
    required this.isHackathon,
    required this.applyUrl,
    required this.contactInfo,
    required this.approved,
    required this.registeredUsers,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] as String? ?? '',
      desc: map['desc'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      organizer: map['organizer'] as String? ?? '',
      organizerId: map['organizerId'] as String? ?? '',
      location: map['location'] as String? ?? '',
      isHackathon: map['isHackathon'] as bool? ?? false,
      applyUrl: map['applyUrl'] as String? ?? '',
      contactInfo: map['contactInfo'] as String? ?? '',
      approved: map['approved'] as bool? ?? false,
      registeredUsers: List<String>.from(map['registeredUsers'] as List<dynamic>? ?? <String>[]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'desc': desc,
      'date': Timestamp.fromDate(date),
      'organizer': organizer,
      'organizerId': organizerId,
      'location': location,
      'isHackathon': isHackathon,
      'applyUrl': applyUrl,
      'contactInfo': contactInfo,
      'approved': approved,
      'registeredUsers': registeredUsers,
    };
  }
}
