import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubit/chat_cubit.dart';
import 'admin_chat_screen.dart';

class AdminChatList extends StatefulWidget {
  const AdminChatList({super.key});

  @override
  State<AdminChatList> createState() => _AdminChatListState();
}

class _AdminChatListState extends State<AdminChatList> {
  bool _showHelpMessage = true;

  // Prewritten help message
  final String _helpMessage =
      "💬 Chat Center\n\n"
      "• View all customer conversations\n"
      "• Tap any chat to open conversation\n"
      "• Unread messages are highlighted in red\n"
      "• Send messages directly to customers\n\n"
      "Use this center to provide customer support and resolve queries!";

  @override
  void initState() {
    super.initState();

    // Auto-hide the help message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showHelpMessage = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Support Chats'),
        elevation: 4,
        shadowColor: Colors.black26,
        actions: [
          // Optional: Add a help button to show message again
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              setState(() {
                _showHelpMessage = true;
              });

              // Auto-hide after 5 seconds
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  setState(() {
                    _showHelpMessage = false;
                  });
                }
              });
            },
            tooltip: 'Show help',
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: context.read<ChatCubit>().getAllChats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final chats = snapshot.data!;

              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No customer chats yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customer chats will appear here',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

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

          // Help message overlay
          if (_showHelpMessage)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildHelpMessage(context),
            ),
        ],
      ),

      // Optional: Floating help button as alternative
     /* floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _showHelpMessage = true;
          });

          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _showHelpMessage = false;
              });
            }
          });
        },
        icon: const Icon(Icons.help_outline),
        label: const Text('Help'),
        backgroundColor: Colors.blue[600],
      ),*/
    );
  }

  Widget _buildHelpMessage(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.blue[200]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.support_agent,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Customer Support Guide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.blue[700],
                  ),
                  onPressed: () {
                    setState(() {
                      _showHelpMessage = false;
                    });
                  },
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _helpMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[900],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 1.0,
              backgroundColor: Colors.blue[100],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
              minHeight: 3,
            ),
          ],
        ),
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