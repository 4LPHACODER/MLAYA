import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/local_notification_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._localDataSource);

  final LocalNotificationDataSource _localDataSource;
  static const Duration _duplicateWindow = Duration(hours: 6);

  @override
  Future<List<AppNotification>> getNotifications() async {
    final items = await _localDataSource.readAll();
    return _sorted(items.map((item) => item.toEntity()).toList());
  }

  @override
  Future<List<AppNotification>> addNotification(AppNotification notification) async {
    final currentModels = await _localDataSource.readAll();
    final now = DateTime.now();
    final isDuplicate = currentModels.any(
      (item) =>
          item.type == notification.type &&
          item.title == notification.title &&
          item.message == notification.message &&
          now.difference(item.createdAt) <= _duplicateWindow,
    );

    if (isDuplicate) {
      return _sorted(currentModels.map((item) => item.toEntity()).toList());
    }

    final updated = [
      NotificationModel.fromEntity(notification),
      ...currentModels,
    ];
    await _localDataSource.writeAll(updated);
    return _sorted(updated.map((item) => item.toEntity()).toList());
  }

  @override
  Future<List<AppNotification>> markNotificationAsRead(String id) async {
    final currentModels = await _localDataSource.readAll();
    final updated = currentModels
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    await _localDataSource.writeAll(updated);
    return _sorted(updated.map((item) => item.toEntity()).toList());
  }

  @override
  Future<List<AppNotification>> markAllNotificationsAsRead() async {
    final currentModels = await _localDataSource.readAll();
    final updated = currentModels
        .map((item) => item.copyWith(isRead: true))
        .toList();
    await _localDataSource.writeAll(updated);
    return _sorted(updated.map((item) => item.toEntity()).toList());
  }

  @override
  Future<List<AppNotification>> clearNotifications() async {
    await _localDataSource.writeAll(const []);
    return const [];
  }

  List<AppNotification> _sorted(List<AppNotification> notifications) {
    final items = [...notifications];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
}
