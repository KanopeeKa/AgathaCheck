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
    );
  }

  @override
  Future<NotificationPreferences> updatePreferences(
      NotificationPreferences preferences) async {
    final model = NotificationPreferencesModel(
      emailRemindersEnabled: preferences.emailRemindersEnabled,
      reminderDaysBefore: preferences.reminderDaysBefore,
      notifyOverdue: preferences.notifyOverdue,
      notifyDueSoon: preferences.notifyDueSoon,
    );
    final result = await _dataSource.updatePreferences(_tokenGetter(), model);
    return NotificationPreferences(
      emailRemindersEnabled: result.emailRemindersEnabled,
      reminderDaysBefore: result.reminderDaysBefore,
      notifyOverdue: result.notifyOverdue,
      notifyDueSoon: result.notifyDueSoon,
    );
  }

  @override
  Future<void> checkDueEntries({Map<String, String> petNames = const {}}) async {
    await _dataSource.checkDueEntries(_tokenGetter(), petNames: petNames);
  }
}
