import '../entities/app_notification.dart';
import '../entities/notification_preferences.dart';
import '../services/notification_inbox_v2_rules.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead({
    NotificationInboxTab scope = NotificationInboxTab.activity,
  });
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  );
  Future<void> dismissV2InboxExplainer();
  Future<void> dismissDeviceSecurityIntro();
  Future<void> checkDueEntries({Map<String, String> petNames = const {}});
  Future<void> markSuggestionsSeen({String? petId});
  Future<void> submitSuggestionFeedback(String notificationId, String action);
  Future<void> submitAccountSecurityFeedback(
    String notificationId,
    String action,
  );
}
