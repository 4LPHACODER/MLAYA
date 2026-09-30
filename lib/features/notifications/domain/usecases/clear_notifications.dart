import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class ClearNotificationsUsecase {
  final NotificationRepository repository;

  ClearNotificationsUsecase(this.repository);

  Future<List<AppNotification>> call() async {
    return repository.clearNotifications();
  }
}
