import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

        // Group messages by date
        final Map<String, List<Map<String, dynamic>>> groupedMessages = {};

        for (var message in messages) {
          if (message == null) continue;

          // get timestamp from Firestore Timestamp to DateTime
          final timestamp = message['timestamp'];
          if (timestamp == null) continue;

          final DateTime messageDate = timestamp.toDate();
          final String dateKey = DateFormat('yyyy-MM-dd').format(messageDate);

          groupedMessages.putIfAbsent(dateKey, () => []);
          groupedMessages[dateKey]!.add(message);
        }

        // Sort date keys OLD → NEW (oldest first)
        final sortedDates = groupedMessages.keys.toList()
          ..sort((a, b) => a.compareTo(b)); // ascending sort: oldest first

        // Build UI widgets
        final List<Widget> messageWidgets = [];

        for (final dateKey in sortedDates) {
          final dayMessages = groupedMessages[dateKey]!;

          // sort messages in that day by timestamp (oldest first)
          dayMessages.sort((a, b) {
            final DateTime aTime = a['timestamp'].toDate();
            final DateTime bTime = b['timestamp'].toDate();
            return aTime.compareTo(bTime);
          });

          // parse date for header display
          final DateTime headerDate = DateTime.parse(dateKey);
          messageWidgets.add(_buildDateHeader(headerDate)); // date header ABOVE messages

          // add messages for this day (in sorted order)
          for (final message in dayMessages) {
            messageWidgets.add(
              _buildMessageBubble(message, context),
            );
          }
        }

        // Add pending message at the end if it exists
        if (_pendingMessageText != null) {
          messageWidgets.add(_buildPendingMessage());
        }

        return ListView.builder(
          reverse: false,
          padding: const EdgeInsets.all(12),
          itemCount: messageWidgets.length,
          itemBuilder: (context, index) {
            return messageWidgets[index];
          },
        );
      },
    );
  }

  // Build WhatsApp-style date header (placed at the TOP of messages for that day)
  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;

    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else if (messageDate.year == now.year) {
      // Same year, show day and month in uppercase
      dateText = DateFormat('dd MMM').format(date).toUpperCase(); // "15 JAN"
    } else {
      // Different year, show full date with year
      dateText = DateFormat('dd MMM yyyy').format(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingMessage() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Icon for admin (customer/support agent on LEFT)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepOrangeAccent.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.support_agent,
              size: 16,
              color: Colors.deepOrangeAccent,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepOrangeAccent.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pendingMessageText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(Timestamp.now()),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
        mainAxisAlignment: isAdminMessage ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAdminMessage) ...[
            // Icon for admin messages (customer/support agent on LEFT)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepOrangeAccent.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.support_agent,
                size: 16,
                color: Colors.deepOrangeAccent,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdminMessage
                  ? Colors.deepOrangeAccent
                  : (!isRead && !isAdminMessage
                  ? Colors.red[100]
                  : Colors.blue[600]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isAdminMessage
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
                bottomRight: isAdminMessage
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
              ),
              border: !isRead && !isAdminMessage
                  ? Border.all(color: Colors.red[300]!, width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: isAdminMessage
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  message['text'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                // REMOVED ALL CHECK MARK ICONS - ONLY TIMESTAMP REMAINS
                Text(
                  _formatTimestamp(message['timestamp']),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (!isAdminMessage) ...[
            const SizedBox(width: 8),
            // Icon for user messages (person icon on RIGHT)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[600]!.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.blue,
              ),
            ),
          ],
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
              color: _isSending ? Colors.grey : Colors.deepOrangeAccent,
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    try {
      final date = timestamp.toDate();
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return 'Just now';
    }
  }
}