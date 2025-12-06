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

    if (isAdmin) {
      // Admin sending a message
      // Update lastActive and lastMessage for the chat
      await chatDocRef.set({
        'lastActive': FieldValue.serverTimestamp(),
        'lastMessage': text,
        'unread': 0, // Initialize unread to 0 for admin messages
      }, SetOptions(merge: true));

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
    } else {
      // User sending a message: increment unread count
      // First, get the current unread count
      final chatDoc = await chatDocRef.get();
      final currentUnread = chatDoc.exists && chatDoc.data() != null
          ? (chatDoc.data()!['unread'] ?? 0)
          : 0;

      // Update lastActive, lastMessage, and unread count
      await chatDocRef.set({
        'lastActive': FieldValue.serverTimestamp(),
        'lastMessage': text,
        'unread': currentUnread + 1, // Explicitly set to current + 1
      }, SetOptions(merge: true));
    }
  }

  @override
  Stream<int> getUnreadCount(String userId) {
    return _firestore.collection('chats').doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('unread')) {
          return data['unread'] ?? 0;
        }
      }
      return 0;
    });
  }

  @override
  Future<void> markMessagesAsRead(String userId) async {
    final chatDocRef = _firestore.collection('chats').doc(userId);

    // Mark all user's unread messages as read
    final unreadMessages = await _firestore.collection('chats').doc(userId)
        .collection('messages')
        .where('sender', isEqualTo: 'user')
        .where('read', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      // Reset unread count to 0
      await chatDocRef.set({
        'unread': 0,
      }, SetOptions(merge: true));
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getMessages(String userId) {
    return _firestore.collection('chats').doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'text': data['text'] ?? '',
        'sender': data['sender'] ?? 'user',
        'timestamp': data['timestamp'],
        'read': data['read'] ?? false,
      };
    }).toList());
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
          'userName': userData['name'] ?? 'Unknown User',
          'lastMessage': chatDoc['lastMessage'] ?? 'No messages',
          'unread': chatDoc['unread'] ?? 0,
          'lastActive': chatDoc['lastActive'],
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