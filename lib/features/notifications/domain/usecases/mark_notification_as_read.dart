import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationAsReadUsecase {
  final NotificationRepository repository;

  MarkNotificationAsReadUsecase(this.repository);

  Future<List<AppNotification>> call(String id) async {
    return repository.markNotificationAsRead(id);
  }
}
