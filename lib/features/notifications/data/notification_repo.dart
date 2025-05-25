import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseNotificationsRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'title': data['title'],
        'body': data['body'],
        'timestamp': data['timestamp']?.toDate(),
        'type': data['type'],
        'chatUserId': data['chatUserId'],
      };
    }).toList());
  }
}