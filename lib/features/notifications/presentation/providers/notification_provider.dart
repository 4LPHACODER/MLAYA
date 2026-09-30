import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local_notification_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/add_notification.dart';
import '../../domain/usecases/clear_notifications.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_all_notifications_as_read.dart';
import '../../domain/usecases/mark_notification_as_read.dart';

class NotificationState {
  final bool isLoading;
  final List<AppNotification> notifications;

  const NotificationState({required this.isLoading, required this.notifications});

  const NotificationState.initial()
    : isLoading = true,
      notifications = const [];

  NotificationState copyWith({
    bool? isLoading,
    List<AppNotification>? notifications,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
    );
  }
}

final localNotificationDataSourceProvider = Provider<LocalNotificationDataSource>(
  (ref) => LocalNotificationDataSource(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dataSource = ref.watch(localNotificationDataSourceProvider);
  return NotificationRepositoryImpl(dataSource);
});

final getNotificationsUsecaseProvider = Provider<GetNotificationsUsecase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return GetNotificationsUsecase(repository);
});

final addNotificationUsecaseProvider = Provider<AddNotificationUsecase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return AddNotificationUsecase(repository);
});

final markNotificationAsReadUsecaseProvider =
    Provider<MarkNotificationAsReadUsecase>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      return MarkNotificationAsReadUsecase(repository);
    });

final markAllNotificationsAsReadUsecaseProvider =
    Provider<MarkAllNotificationsAsReadUsecase>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      return MarkAllNotificationsAsReadUsecase(repository);
    });

final clearNotificationsUsecaseProvider = Provider<ClearNotificationsUsecase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return ClearNotificationsUsecase(repository);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(
    this._getNotificationsUsecase,
    this._addNotificationUsecase,
    this._markNotificationAsReadUsecase,
    this._markAllNotificationsAsReadUsecase,
    this._clearNotificationsUsecase,
  ) : super(const NotificationState.initial()) {
    loadNotifications();
  }

  final GetNotificationsUsecase _getNotificationsUsecase;
  final AddNotificationUsecase _addNotificationUsecase;
  final MarkNotificationAsReadUsecase _markNotificationAsReadUsecase;
  final MarkAllNotificationsAsReadUsecase _markAllNotificationsAsReadUsecase;
  final ClearNotificationsUsecase _clearNotificationsUsecase;

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final notifications = await _getNotificationsUsecase();
      state = state.copyWith(isLoading: false, notifications: notifications);
    } catch (_) {
      state = state.copyWith(isLoading: false, notifications: const []);
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? spotName,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}_${type.name}_${title.hashCode}';
    final notification = AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: now,
      isRead: false,
      spotName: spotName,
      latitude: latitude,
      longitude: longitude,
    );
    try {
      final notifications = await _addNotificationUsecase(notification);
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final notifications = await _markNotificationAsReadUsecase(id);
      state = state.copyWith(notifications: notifications);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final notifications = await _markAllNotificationsAsReadUsecase();
      state = state.copyWith(notifications: notifications);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final notifications = await _clearNotificationsUsecase();
      state = state.copyWith(notifications: notifications);
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final getNotifications = ref.watch(getNotificationsUsecaseProvider);
      final addNotification = ref.watch(addNotificationUsecaseProvider);
      final markAsRead = ref.watch(markNotificationAsReadUsecaseProvider);
      final markAll = ref.watch(markAllNotificationsAsReadUsecaseProvider);
      final clear = ref.watch(clearNotificationsUsecaseProvider);
      return NotificationNotifier(
        getNotifications,
        addNotification,
        markAsRead,
        markAll,
        clear,
      );
    });

final notificationsListProvider = Provider<List<AppNotification>>((ref) {
  return ref.watch(notificationsProvider).notifications;
});

final unreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationsListProvider)
      .where((notification) => !notification.isRead)
      .length;
});
