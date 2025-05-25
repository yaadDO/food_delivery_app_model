import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_cubit.dart';
import '../../../chat/presentation/pages/user_chat_screen.dart';
import '../../data/notification_repo.dart';
import '../cubits/notifications_cubit.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final userId = context.read<AuthCubit>().currentUser?.uid ?? '';
    context.read<NotificationsCubit>().loadNotifications(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: BlocConsumer<NotificationsCubit, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationsLoaded) {
            return _buildNotificationsList(state.notifications);
          }

          return const Center(child: Text('No notifications found'));
        },
      ),
    );
  }

  Widget _buildNotificationsList(Stream<List<Map<String, dynamic>>> notifications) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: notifications,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!;

        if (notifications.isEmpty) {
          return const Center(child: Text('No notifications available'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(notification['title'] ?? 'No Title'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['body'] ?? 'No Content'),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification['timestamp']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              onTap: () {
                if (notification['type'] == 'chat') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserChatScreen(
                        userId: notification['chatUserId'] ?? '',
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} - '
        '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}