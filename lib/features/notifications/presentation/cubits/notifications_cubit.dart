import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/notification_repo.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final FirebaseNotificationsRepo repo;
  String? _currentUserId;
  StreamSubscription? _notificationSubscription;

  NotificationsCubit(this.repo) : super(NotificationsInitial());

  void loadNotifications(String userId) {
    // Cancel any existing subscription before loading new notifications
    _notificationSubscription?.cancel();
    _notificationSubscription = null;

    if (_currentUserId == userId && state is NotificationsLoaded) return;

    _currentUserId = userId;

    emit(NotificationsLoading());

    try {
      final notificationStream = repo.getNotifications(userId);

      // Listen to the stream and handle state properly
      _notificationSubscription = notificationStream.listen(
            (notifications) {
          emit(NotificationsLoaded(notificationStream));
        },
        onError: (error) {
          emit(NotificationsError(error.toString()));
          // Reset to initial state after error
          Future.delayed(const Duration(seconds: 2), () => emit(NotificationsInitial()));
        },
      );
    } catch (e) {
      emit(NotificationsError(e.toString()));
      // Reset to initial state after error
      Future.delayed(const Duration(seconds: 2), () => emit(NotificationsInitial()));
    }
  }

  void refreshNotifications() {
    if (_currentUserId != null) {
      loadNotifications(_currentUserId!);
    }
  }

  // NEW: Reset notifications when user logs out
  void reset() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
    emit(NotificationsInitial());
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}