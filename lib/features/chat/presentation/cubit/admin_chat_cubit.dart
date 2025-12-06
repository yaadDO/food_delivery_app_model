import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/chat_repo.dart';


class AdminChatCubit extends Cubit<AdminChatState> {
  final ChatRepo chatRepo;
  AdminChatCubit(this.chatRepo) : super(AdminChatInitial());

  Future<void> sendMessage(String userId, String text) async {
    try {
      emit(AdminChatSending());
      await chatRepo.sendMessage(userId, text, true);
      emit(AdminChatSent());
    } catch (e) {
      emit(AdminChatError(e.toString()));
    }
  }
}

abstract class AdminChatState {}

class AdminChatInitial extends AdminChatState {}

class AdminChatSending extends AdminChatState {}

class AdminChatSent extends AdminChatState {}

class AdminChatError extends AdminChatState {
  final String message;
  AdminChatError(this.message);
}