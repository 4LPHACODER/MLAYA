import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();

  Future<List<AppNotification>> addNotification(AppNotification notification);

  Future<List<AppNotification>> markNotificationAsRead(String id);

  Future<List<AppNotification>> markAllNotificationsAsRead();

  Future<List<AppNotification>> clearNotifications();
}
