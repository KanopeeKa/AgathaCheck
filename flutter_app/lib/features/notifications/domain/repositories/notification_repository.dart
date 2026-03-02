import '../entities/app_notification.dart';
import '../entities/notification_preferences.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences(
      NotificationPreferences preferences);
  Future<void> checkDueEntries({Map<String, String> petNames = const {}});
}
