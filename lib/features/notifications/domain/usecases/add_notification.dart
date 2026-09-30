import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class AddNotificationUsecase {
  final NotificationRepository repository;

  AddNotificationUsecase(this.repository);

  Future<List<AppNotification>> call(AppNotification notification) async {
    return repository.addNotification(notification);
  }
}
