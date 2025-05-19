import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/chat_cubit.dart';
import 'admin_chat_screen.dart';

class AdminChatList extends StatelessWidget {
  const AdminChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Chats')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<ChatCubit>().getAllChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                title: Text('User: ${chat['userName']}'), // Use 'userName' instead of 'userId'
                subtitle: Text(chat['lastMessage']),
                trailing: chat['unread'] > 0
                    ? CircleAvatar(child: Text(chat['unread'].toString()))
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminChatScreen(userId: chat['userId']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
