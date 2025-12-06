import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/chat_cubit.dart';

class AdminChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const AdminChatScreen({
    super.key,
    required this.userId,
    required this.userName
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;
  List<Map<String, dynamic>> _cachedMessages = [];
  Stream<List<Map<String, dynamic>>>? _messageStream;
  String? _pendingMessageText;
  String? _pendingMessageId;

  @override
  void initState() {
    super.initState();
    // Get the stream once and cache it
    _messageStream = context.read<ChatCubit>().getMessages(widget.userId);

    // Mark messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatCubit>().markMessagesAsRead(widget.userId);
    });
  }

  Stream<List<Map<String, dynamic>>> _getSafeStream() {
    return _messageStream!.asyncMap((messages) async {
      // Check if we need to remove pending message
      if (_pendingMessageId != null) {
        // Look for a message with similar text that was just sent
        final now = DateTime.now();
        for (final message in messages) {
          final timestamp = message['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final messageTime = timestamp.toDate();
            final timeDiff = now.difference(messageTime).inSeconds;

            // If we find a message with the same text that was sent recently (within 3 seconds)
            if (message['text'] == _pendingMessageText &&
                timeDiff < 3 &&
                message['sender'] == 'admin') {
              // Found the real message, clear pending AND reset sending state
              setState(() {
                _pendingMessageText = null;
                _pendingMessageId = null;
                _isSending = false; // RESET THE SENDING STATE HERE
              });
              break;
            }
          }
        }
      }

      return messages;
    }).handleError((error) {
      // When there's an error, return the cached messages
      return _cachedMessages;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.inversePrimary,
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<ChatCubit>().getAllChats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final chat = snapshot.data!.firstWhere(
                      (chat) => chat['userId'] == widget.userId,
                  orElse: () => {'unread': 0},
                );

                final unreadCount = chat['unread'] ?? 0;
                if (unreadCount <= 0) return const SizedBox.shrink();

                return Text(
                  '$unreadCount unread message${unreadCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                );
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
            child: _buildMessageList(),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getSafeStream(),
      builder: (context, snapshot) {
        // Update cache when we get new data
        if (snapshot.hasData) {
          _cachedMessages = snapshot.data!;
        }

        if (snapshot.hasError) {
          // Should never reach here due to error handling, but just in case
          print('Stream error: ${snapshot.error}');
        }

        List<Map<String, dynamic>> messages = snapshot.hasData ? snapshot.data! : _cachedMessages;

        // Remove any message that matches our pending message text
        // to avoid showing both pending and real message
        if (_pendingMessageText != null) {
          messages = messages.where((msg) =>
          msg['text'] != _pendingMessageText ||
              msg['sender'] != 'admin' ||
              (msg['isPending'] == true) // Keep if it's marked as pending
          ).toList();
        }

        if (messages.isEmpty && !snapshot.hasData && snapshot.connectionState != ConnectionState.waiting) {
          return const Center(child: Text('No messages yet'));
        }

        if (messages.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length + (_pendingMessageText != null ? 1 : 0),
          itemBuilder: (context, index) {
            // Handle pending message
            if (_pendingMessageText != null && index == 0) {
              return _buildPendingMessage();
            }

            // Adjust index for real messages
            final messageIndex = _pendingMessageText != null ? index - 1 : index;
            final message = messages[messageIndex];
            return _buildMessageBubble(message, context);
          },
        );
      },
    );
  }

  Widget _buildPendingMessage() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _pendingMessageText!,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(Timestamp.now()),
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
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
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, BuildContext context) {
    final theme = Theme.of(context);
    final isAdminMessage = message['sender'] == 'admin';
    final bool isRead = message['read'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isAdminMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isAdminMessage
                  ? theme.colorScheme.primary
                  : (!isRead && !isAdminMessage
                  ? Colors.red[100]
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
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
              enabled: !_isSending,
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
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSending ? Colors.grey : Colors.red,
            ),
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _isSending) return;

    final text = _controller.text;
    final pendingId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _isSending = true;
      _pendingMessageText = text;
      _pendingMessageId = pendingId;
    });

    try {
      // Send message without waiting for ChatCubit state
      await context.read<ChatCubit>().sendMessage(widget.userId, text, true);
      _controller.clear();

      // Set a timeout to reset the sending state if it takes too long
      // This is a safety net in case the stream doesn't update properly
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isSending) {
          setState(() {
            _pendingMessageText = null;
            _pendingMessageId = null;
            _isSending = false;
          });
        }
      });
    } catch (e) {
      // Show error but don't crash the UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Reset the sending state on error
      setState(() {
        _pendingMessageText = null;
        _pendingMessageId = null;
        _isSending = false;
      });
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}