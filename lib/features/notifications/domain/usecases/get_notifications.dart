import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUsecase {
  final NotificationRepository repository;

  GetNotificationsUsecase(this.repository);

  Future<List<AppNotification>> call() async {
    return repository.getNotifications();
  }
}
