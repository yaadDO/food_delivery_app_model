import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/notification_repo.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final FirebaseNotificationsRepo repo;
  String? _currentUserId;

  NotificationsCubit(this.repo) : super(NotificationsInitial());

  void loadNotifications(String userId) {
    if (_currentUserId == userId && state is NotificationsLoaded) return;

    _currentUserId = userId;

    emit(NotificationsLoading());

    try {
      final notificationStream = repo.getNotifications(userId);
      emit(NotificationsLoaded(notificationStream));
    } catch (e) {
      emit(NotificationsError(e.toString()));
      // Re-emit previous state after error if needed
      Future.delayed(const Duration(seconds: 2), () => emit(NotificationsInitial()));
    }
  }

  void refreshNotifications() {
    if (_currentUserId != null) {
      loadNotifications(_currentUserId!);
    }
  }
}
