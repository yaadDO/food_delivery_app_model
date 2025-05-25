import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/repository/chat_repo.dart';

class FirebaseChatRepo implements ChatRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendMessage(String userId, String text, bool isAdmin) async {
    // Add the new message
    await _firestore.collection('chats').doc(userId).collection('messages').add({
      'text': text,
      'sender': isAdmin ? 'admin' : 'user',
      'timestamp': FieldValue.serverTimestamp(),
      'read': isAdmin, // Admin messages are marked as read
    });

    // Reference to the chat document
    final chatDocRef = _firestore.collection('chats').doc(userId);

    // Update lastActive and lastMessage for the chat
    await chatDocRef.set({
      'lastActive': FieldValue.serverTimestamp(),
      'lastMessage': text,
    }, SetOptions(merge: true));

    if (isAdmin) {
      // Mark all user's unread messages as read
      final unreadMessages = await _firestore.collection('chats').doc(userId)
          .collection('messages')
          .where('sender', isEqualTo: 'user')
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      // Decrease unread count by the number of messages marked read
      await chatDocRef.update({
        'unread': FieldValue.increment(-unreadMessages.size),
      });
    } else {
      // User sent a message: increment unread count
      await chatDocRef.update({
        'unread': FieldValue.increment(1),
      });
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getMessages(String userId) {
    return _firestore.collection('chats').doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> getAllChats() {
    return _firestore.collection('chats')
        .orderBy('lastActive', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final chats = <Map<String, dynamic>>[];
      for (final chatDoc in snapshot.docs) {
        final userId = chatDoc.id;
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};

        chats.add({
          'userId': userId,
          'userName': userData['name'] ?? 'Unknown User', // Fetch name
          'lastMessage': chatDoc['lastMessage'] ?? 'No messages',
          'unread': chatDoc['unread'] ?? 0,
        });
      }
      return chats;
    });
  }
  Future<void> _sendNotification(String userId, String message, bool isAdmin) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final token = userDoc.data()?['fcmToken'];

      if (token == null) return;

      // Determine notification content
      final title = isAdmin ? 'New Support Message' : 'Customer Message';
      final body = isAdmin ? message : 'You have a new customer message';

      // Send notification via Firebase Functions (you'll need to create this endpoint)
      await _firestore.collection('notifications').add({
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'type': 'chat',
          'userId': userId,
        }
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

}