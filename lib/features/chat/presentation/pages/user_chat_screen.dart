import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/chat_cubit.dart';

class UserChatScreen extends StatefulWidget {
  final String userId;
  const UserChatScreen({super.key, required this.userId});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showHelpMessage = true;
  final ScrollController _scrollController = ScrollController();

  // Prewritten help message for customers
  final String _helpMessage =
      "💬 Customer Support Chat\n\n"
      "• Send messages to our support team\n"
      "• We'll respond as soon as possible\n"
      "• Describe your issue clearly for faster resolution\n\n"
      "Our team is here to help you!";

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'chat') {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => UserChatScreen(userId: message.data['userId'])
        ));
      }
    });

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
        title: const Text('Support Chat'),
        actions: [
          // Help button to show message again
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
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: context.read<ChatCubit>().getMessages(widget.userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final messages = snapshot.data!;

                    // ---------- Group messages by date ----------
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

                    // ---------- Sort date keys OLD → NEW (oldest first) ----------
                    final sortedDates = groupedMessages.keys.toList()
                      ..sort((a, b) => a.compareTo(b)); // ascending sort: oldest first

                    // ---------- Build UI widgets ----------
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
                        final isUserMessage = message['sender'] == 'user';

                        // Get message date for timestamp
                        DateTime? messageDate;
                        if (message['timestamp'] != null) {
                          try {
                            messageDate = message['timestamp'].toDate();
                          } catch (e) {
                            messageDate = null;
                          }
                        }

                        messageWidgets.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            child: Row(
                              mainAxisAlignment: isUserMessage
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                if (!isUserMessage) ...[
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
                                    color: isUserMessage
                                        ? Colors.blue[600]
                                        : Colors.deepOrangeAccent,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: isUserMessage
                                          ? const Radius.circular(16)
                                          : const Radius.circular(4),
                                      bottomRight: isUserMessage
                                          ? const Radius.circular(4)
                                          : const Radius.circular(16),
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
                                    crossAxisAlignment: isUserMessage
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['text'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatMessageTime(messageDate ?? DateTime.now()),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isUserMessage) ...[
                                  const SizedBox(width: 8),
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
                          ),
                        );
                      }
                    }

                    if (messageWidgets.isEmpty) {
                      return const Center(
                        child: Text('No messages yet'),
                      );
                    }

                    return ListView.builder(
                      reverse: false,
                      controller: _scrollController,
                      itemCount: messageWidgets.length,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemBuilder: (context, index) {
                        return messageWidgets[index];
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                style: const TextStyle(
                                  color: Colors.black, // Input text color set to black
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(
                                    color: Colors.black54, // Hint text color set to black with opacity
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                maxLines: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[600],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            context.read<ChatCubit>().sendMessage(
                                widget.userId,
                                _controller.text,
                                false // isAdmin
                            );
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  // Format message timestamp like WhatsApp (HH:mm)
  String _formatMessageTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
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
                      'Chat Help',
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
}