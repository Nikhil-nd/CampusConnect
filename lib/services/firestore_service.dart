import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_model.dart';
import '../models/job_model.dart';
import '../models/lost_found_model.dart';
import '../models/marketplace_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get currentUserId => _uid;

  bool _isUpcoming(DateTime date) {
    return !date.isBefore(DateTime.now());
  }

  Future<void> upsertUserProfile({
    required String name,
    required String email,
    required String branch,
    required int year,
  }) async {
    await _db.collection('users').doc(_uid).set(
      <String, dynamic>{
        'name': name,
        'email': email,
        'branch': branch,
        'year': year,
        'profilePic': '',
        'reputation': 0,
        'isAdmin': false,
        'isBanned': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<UserModel?> watchCurrentUser() {
    return _db.collection('users').doc(_uid).snapshots().map((DocumentSnapshot<Map<String, dynamic>> doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<MarketplaceModel>> watchMarketplace({String search = '', bool lowToHigh = true}) {
    return _db.collection('marketplace').snapshots().map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final String q = search.trim().toLowerCase();
      final List<MarketplaceModel> items = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => MarketplaceModel.fromMap(doc.data(), doc.id))
          .where((MarketplaceModel item) => item.status == 'available')
          .where((MarketplaceModel item) {
            if (q.isEmpty) {
              return true;
            }
            return item.title.toLowerCase().contains(q) ||
                item.description.toLowerCase().contains(q) ||
                item.category.toLowerCase().contains(q);
          })
          .toList();

      items.sort((MarketplaceModel a, MarketplaceModel b) {
        return lowToHigh ? a.price.compareTo(b.price) : b.price.compareTo(a.price);
      });
      return items;
    });
  }

  Future<void> createMarketplacePost(MarketplaceModel model) {
    return _db.collection('marketplace').add(model.toMap());
  }

  Future<void> markMarketplaceSold(String postId) {
    return _db.collection('marketplace').doc(postId).update(<String, dynamic>{'status': 'sold'});
  }

  Stream<List<EventModel>> watchEvents({String search = '', bool includeMyPending = false}) {
    return _db
        .collection('events')
        .orderBy('date')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<EventModel> allEvents = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();

      final List<EventModel> events = allEvents.where((EventModel event) {
        if (!_isUpcoming(event.date)) {
          return false;
        }
        if (event.approved) {
          return true;
        }
        return includeMyPending && event.organizerId == _uid;
      }).toList();

      if (search.trim().isEmpty) {
        return events;
      }
      final String q = search.toLowerCase();
      return events.where((EventModel event) {
        return event.title.toLowerCase().contains(q) ||
            event.desc.toLowerCase().contains(q) ||
            event.location.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> createEvent(EventModel event) {
    return _db.collection('events').add(event.toMap());
  }

  Future<void> registerForEvent(String eventId) {
    return _db.collection('events').doc(eventId).update(<String, dynamic>{
      'registeredUsers': FieldValue.arrayUnion(<String>[_uid]),
    });
  }

  Stream<List<LostFoundModel>> watchLostFound() {
    return _db.collection('lost_found').orderBy('createdAt', descending: true).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => LostFoundModel.fromMap(doc.data(), doc.id))
            .toList();
      },
    );
  }

  Future<void> createLostFound(LostFoundModel item) {
    return _db.collection('lost_found').add(item.toMap());
  }

  Stream<List<JobModel>> watchJobs({String search = ''}) {
    return _db.collection('jobs').orderBy('createdAt', descending: true).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<JobModel> jobs = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => JobModel.fromMap(doc.data(), doc.id))
            .toList();
        if (search.trim().isEmpty) {
          return jobs;
        }
        final String q = search.toLowerCase();
        return jobs.where((JobModel job) {
          return job.title.toLowerCase().contains(q) ||
              job.desc.toLowerCase().contains(q) ||
              job.pay.toLowerCase().contains(q);
        }).toList();
      },
    );
  }

  Future<void> createJob(JobModel job) {
    return _db.collection('jobs').add(job.toMap());
  }

  Future<void> addRating({required String sellerId, required int rating}) {
    return _db.collection('ratings').add(<String, dynamic>{
      'sellerId': sellerId,
      'rating': rating,
      'ratedBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportSpam({
    required String entityType,
    required String entityId,
    required String reason,
    String entityTitle = '',
  }) {
    return _db.collection('reports').add(<String, dynamic>{
      'entityType': entityType,
      'entityId': entityId,
      'entityTitle': entityTitle,
      'reason': reason,
      'reportedBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'resolved': false,
    });
  }

  Stream<List<ReportModel>> watchReports({bool unresolvedOnly = true}) {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<ReportModel> allReports = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => ReportModel.fromMap(doc.data(), doc.id))
          .toList();

      if (unresolvedOnly) {
        return allReports.where((ReportModel r) => !r.resolved).toList();
      }
      return allReports;
    });
  }

  Future<void> resolveReport(String reportId) async {
    final String trimmedId = reportId.trim();
    if (trimmedId.isEmpty) {
      throw Exception('Report ID is required.');
    }
    await _db.collection('reports').doc(trimmedId).update(<String, dynamic>{'resolved': true});
  }

  Future<void> approveEvent(String eventId) async {
    final String trimmedId = eventId.trim();
    if (trimmedId.isEmpty) {
      throw Exception('Event ID is required.');
    }
    // Direct update (faster than transaction for single document)
    await _db.collection('events').doc(trimmedId).update(<String, dynamic>{'approved': true});
  }

  Stream<List<EventModel>> watchPendingEvents() {
    return _db.collection('events').where('approved', isEqualTo: false).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<EventModel> events = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => EventModel.fromMap(doc.data(), doc.id))
          .where((EventModel event) => _isUpcoming(event.date))
            .toList();
        events.sort((EventModel a, EventModel b) => a.date.compareTo(b.date));
        return events;
      },
    );
  }

  Future<void> rejectEvent(String eventId) {
    final String trimmedId = eventId.trim();
    if (trimmedId.isEmpty) {
      throw Exception('Event ID is required.');
    }
    return _db.collection('events').doc(trimmedId).delete();
  }

  Future<void> deleteSpamPost(String collection, String docId) {
    return _db.collection(collection).doc(docId).delete();
  }

  Future<void> banUser(String userId) {
    return _db.collection('users').doc(userId).update(<String, dynamic>{'isBanned': true});
  }

  Future<String> createOrGetChat(String otherUserId) async {
    final List<String> participants = <String>[_uid, otherUserId]..sort();
    final QuerySnapshot<Map<String, dynamic>> existing = await _db
        .collection('chats')
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final DocumentReference<Map<String, dynamic>> ref = await _db.collection('chats').add(<String, dynamic>{
      'participants': participants,
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: _uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final WriteBatch batch = _db.batch();
    final DocumentReference<Map<String, dynamic>> msgRef =
        _db.collection('chats').doc(chatId).collection('messages').doc();
    final DocumentReference<Map<String, dynamic>> chatRef = _db.collection('chats').doc(chatId);

    batch.set(msgRef, <String, dynamic>{
      'senderId': _uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(chatRef, <String, dynamic>{
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
