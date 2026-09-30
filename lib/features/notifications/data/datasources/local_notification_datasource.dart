import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

const _notificationsKey = 'notifications.items.v1';

class LocalNotificationDataSource {
  Future<List<NotificationModel>> readAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notificationsKey);
      if (raw == null || raw.isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      final notifications = <NotificationModel>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          notifications.add(NotificationModel.fromJson(item));
        } else if (item is Map) {
          notifications.add(
            NotificationModel.fromJson(item.cast<String, dynamic>()),
          );
        }
      }
      return notifications;
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeAll(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(notifications.map((item) => item.toJson()).toList());
      await prefs.setString(_notificationsKey, encoded);
    } catch (_) {
      // Silent fallback: notification feature should not crash app.
    }
  }
}
