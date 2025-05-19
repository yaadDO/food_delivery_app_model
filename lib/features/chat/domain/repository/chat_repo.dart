import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatRepo {
  Future<void> sendMessage(String userId, String text, bool isAdmin);
  Stream<List<Map<String, dynamic>>> getMessages(String userId);
  Stream<List<Map<String, dynamic>>> getAllChats();
}