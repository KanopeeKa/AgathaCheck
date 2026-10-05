import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dataSource, this._tokenGetter);

  final NotificationRemoteDataSource _dataSource;
  final String Function() _tokenGetter;

  @override
  Future<List<AppNotification>> getNotifications() async {
    return _dataSource.getNotifications(_tokenGetter());
  }

  @override
  Future<int> getUnreadCount() async {
    return _dataSource.getUnreadCount(_tokenGetter());
  }

  @override
  Future<void> markAsRead(String id) async {
    await _dataSource.markAsRead(_tokenGetter(), id);
  }

  @override
  Future<void> markAllAsRead() async {
    await _dataSource.markAllAsRead(_tokenGetter());
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    final model = await _dataSource.getPreferences(_tokenGetter());
    return NotificationPreferences(
      emailRemindersEnabled: model.emailRemindersEnabled,
      reminderDaysBefore: model.reminderDaysBefore,
      notifyOverdue: model.notifyOverdue,
      notifyDueSoon: model.notifyDueSoon,
      notifyCompleted: model.notifyCompleted,
      mutedPetIds: model.mutedPetIds,
      v2ExplainerDismissedAt: model.v2ExplainerDismissedAt,
    );
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final model = NotificationPreferencesModel(
      emailRemindersEnabled: preferences.emailRemindersEnabled,
      reminderDaysBefore: preferences.reminderDaysBefore,
      notifyOverdue: preferences.notifyOverdue,
      notifyDueSoon: preferences.notifyDueSoon,
      notifyCompleted: preferences.notifyCompleted,
      mutedPetIds: preferences.mutedPetIds,
      v2ExplainerDismissedAt: preferences.v2ExplainerDismissedAt,
    );
    final result = await _dataSource.updatePreferences(_tokenGetter(), model);
    return NotificationPreferences(
      emailRemindersEnabled: result.emailRemindersEnabled,
      reminderDaysBefore: result.reminderDaysBefore,
      notifyOverdue: result.notifyOverdue,
      notifyDueSoon: result.notifyDueSoon,
      notifyCompleted: result.notifyCompleted,
      mutedPetIds: result.mutedPetIds,
      v2ExplainerDismissedAt: result.v2ExplainerDismissedAt,
    );
  }

  @override
  Future<void> dismissV2InboxExplainer() async {
    await _dataSource.dismissV2InboxExplainer(_tokenGetter());
  }

  @override
  Future<void> checkDueEntries({
    Map<String, String> petNames = const {},
  }) async {
    await _dataSource.checkDueEntries(_tokenGetter(), petNames: petNames);
  }

  @override
  Future<void> markSuggestionsSeen({String? petId}) async {
    await _dataSource.markSuggestionsSeen(_tokenGetter(), petId: petId);
  }

  @override
  Future<void> submitSuggestionFeedback(
    String notificationId,
    String action,
  ) async {
    await _dataSource.submitSuggestionFeedback(
      _tokenGetter(),
      notificationId,
      action,
    );
  }
}
