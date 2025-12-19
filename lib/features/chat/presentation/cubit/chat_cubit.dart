import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repository/chat_repo.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo chatRepo;
  ChatCubit(this.chatRepo) : super(ChatInitial());

  Future<void> sendMessage(String userId, String text, bool isAdmin) async {
    return chatRepo.sendMessage(userId, text, isAdmin);
  }

  Future<void> markMessagesAsRead(String userId) async {
    return chatRepo.markMessagesAsRead(userId);
  }

  Stream<List<Map<String, dynamic>>> getMessages(String userId) {
    return chatRepo.getMessages(userId);
  }

  Stream<List<Map<String, dynamic>>> getAllChats() {
    return chatRepo.getAllChats();
  }

  Stream<int> getUnreadCount(String userId) {
    return chatRepo.getUnreadCount(userId);
  }
}