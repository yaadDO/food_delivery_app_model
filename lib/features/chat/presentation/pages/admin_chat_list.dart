import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubit/chat_cubit.dart';
import 'admin_chat_screen.dart';

class AdminChatList extends StatelessWidget {
  const AdminChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Chats'),
        elevation: 4,
        shadowColor: Colors.black26,
        // REMOVED LOGOUT BUTTON FROM HERE
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.read<ChatCubit>().getAllChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final hasUnread = chat['unread'] > 0;

              return Card(
                elevation: hasUnread ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: hasUnread
                      ? BorderSide(color: Colors.red[300]!, width: 2)
                      : BorderSide.none,
                ),
                color: hasUnread ? Colors.red[50] : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: hasUnread
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    child: Text(
                      chat['userName'][0],
                      style: TextStyle(
                        color: hasUnread
                            ? Colors.white
                            : Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    chat['userName'],
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      color: hasUnread ? Colors.red[900] : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat['lastMessage'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasUnread
                              ? Colors.red[800]
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (chat['lastActive'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatLastActive(chat['lastActive']),
                          style: TextStyle(
                            fontSize: 10,
                            color: hasUnread
                                ? Colors.red[600]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: hasUnread
                      ? CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.red,
                    child: Text(
                      chat['unread'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminChatScreen(
                        userId: chat['userId'],
                        userName: chat['userName'],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatLastActive(Timestamp timestamp) {
    final now = DateTime.now();
    final lastActive = timestamp.toDate();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}