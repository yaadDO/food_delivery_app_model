import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/chat_cubit.dart';

class AdminChatScreen extends StatelessWidget {
  final String userId;
  final String userName;
  const AdminChatScreen(
      {super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    final theme = Theme.of(context);

    // Mark messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatCubit>().markMessagesAsRead(userId);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.inversePrimary,
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<ChatCubit>().getAllChats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final chat = snapshot.data!.firstWhere(
                        (chat) => chat['userId'] == userId,
                    orElse: () => {'unread': 0},
                  );
                  final unreadCount = chat['unread'] ?? 0;
                  if (unreadCount > 0) {
                    return Text(
                      '$unreadCount unread message${unreadCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<ChatCubit>().getMessages(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isAdminMessage = message['sender'] == 'admin';
                    final bool isRead = message['read'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isAdminMessage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isAdminMessage
                                  ? theme.colorScheme.primary
                                  : (!isRead && !isAdminMessage
                                  ? Colors.red[100] // Highlight unread user messages
                                  : Colors.grey[200]),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isAdminMessage
                                    ? const Radius.circular(20)
                                    : const Radius.circular(4),
                                bottomRight: isAdminMessage
                                    ? const Radius.circular(4)
                                    : const Radius.circular(20),
                              ),
                              border: !isRead && !isAdminMessage
                                  ? Border.all(color: Colors.red[300]!, width: 1)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isAdminMessage
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text'],
                                  style: TextStyle(
                                    color: isAdminMessage
                                        ? theme.colorScheme.onPrimary
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTimestamp(message['timestamp']),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: (isAdminMessage
                                            ? theme.colorScheme.onPrimary
                                            : Colors.grey[600])
                                            ?.withOpacity(0.7),
                                      ),
                                    ),
                                    if (isAdminMessage && !isRead)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.check,
                                          size: 10,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    if (isAdminMessage && isRead)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.done_all,
                                          size: 10,
                                          color: Colors.green[200],
                                        ),
                                      ),
                                    if (!isAdminMessage && !isRead)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: theme.colorScheme.tertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon:
                        Icon(Icons.send, color: Colors.red),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            context
                                .read<ChatCubit>()
                                .sendMessage(userId, _controller.text, true);
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(Timestamp timestamp) {
  final date = timestamp.toDate();
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}