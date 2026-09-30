import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class MarkAllNotificationsAsReadUsecase {
  final NotificationRepository repository;

  MarkAllNotificationsAsReadUsecase(this.repository);

  Future<List<AppNotification>> call() async {
    return repository.markAllNotificationsAsRead();
  }
}
