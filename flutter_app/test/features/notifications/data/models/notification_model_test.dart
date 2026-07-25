import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/notifications/data/models/notification_model.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';

void main() {
  group('NotificationModel', () {
    final fullJson = {
      'id': 'notif-1',
      'user_id': 'user-1',
      'pet_id': 'pet-1',
      'pet_name': 'Buddy',
      'health_entry_id': 'entry-1',
      'organization_id': 'org-1',
      'title': 'Medication Due',
      'message': 'Heartgard is due tomorrow',
      'type': 'due_soon',
      'is_read': false,
      'created_at': '2025-06-15T10:00:00.000Z',
    };

    test('fromJson defaults kind from type when kind omitted', () {
      final model = NotificationModel.fromJson(fullJson);
      expect(model.kind, NotificationKind.care);
      expect(model.priority, NotificationPriority.normal);
      expect(model.resolvedAt, isNull);
    });

    test('fromJson parses kind priority and resolved_at', () {
      final model = NotificationModel.fromJson({
        ...fullJson,
        'kind': 'administrative',
        'priority': 'urgent',
        'resolved_at': '2025-06-16T12:00:00.000Z',
      });
      expect(model.kind, NotificationKind.administrative);
      expect(model.priority, NotificationPriority.urgent);
      expect(model.resolvedAt?.toUtc().hour, 12);
    });

    test('fromJson parses all fields correctly', () {
      final model = NotificationModel.fromJson(fullJson);

      expect(model.id, 'notif-1');
      expect(model.userId, 'user-1');
      expect(model.petId, 'pet-1');
      expect(model.petName, 'Buddy');
      expect(model.healthEntryId, 'entry-1');
      expect(model.organizationId, 'org-1');
      expect(model.title, 'Medication Due');
      expect(model.message, 'Heartgard is due tomorrow');
      expect(model.type, NotificationType.dueSoon);
      expect(model.isRead, isFalse);
      expect(model.createdAt.year, 2025);
      expect(model.createdAt.month, 6);
      expect(model.createdAt.day, 15);
    });

    test('fromJson parses all notification types', () {
      final expected = {
        'due_soon': NotificationType.dueSoon,
        'overdue': NotificationType.overdue,
        'reminder': NotificationType.reminder,
        'completed': NotificationType.completed,
        'general': NotificationType.general,
      };
      for (final entry in expected.entries) {
        final model = NotificationModel.fromJson({
          ...fullJson,
          'type': entry.key,
        });
        expect(
          model.type,
          entry.value,
          reason: 'type "${entry.key}" should parse to ${entry.value}',
        );
      }
    });

    test('fromJson defaults unknown type to general', () {
      final json = {...fullJson, 'type': 'unknown_type'};
      final model = NotificationModel.fromJson(json);
      expect(model.type, NotificationType.general);
    });

    test('fromJson handles int id coercion', () {
      final json = {...fullJson, 'id': 42};
      final model = NotificationModel.fromJson(json);
      expect(model.id, '42');
    });

    test('fromJson handles is_read true', () {
      final json = {...fullJson, 'is_read': true};
      final model = NotificationModel.fromJson(json);
      expect(model.isRead, isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'notif-2',
        'user_id': 'user-1',
        'title': 'Test',
        'message': 'Test message',
        'type': 'general',
        'is_read': false,
        'created_at': '2025-01-01T00:00:00.000Z',
      };
      final model = NotificationModel.fromJson(json);

      expect(model.petId, isNull);
      expect(model.petName, isNull);
      expect(model.healthEntryId, isNull);
      expect(model.organizationId, isNull);
    });

    test('fromJson handles null/missing required fields with defaults', () {
      final json = <String, dynamic>{};
      final model = NotificationModel.fromJson(json);

      expect(model.id, '');
      expect(model.userId, '');
      expect(model.title, '');
      expect(model.message, '');
      expect(model.type, NotificationType.general);
      expect(model.isRead, isFalse);
    });

    test('toJson produces correct map with all fields', () {
      final model = NotificationModel.fromJson(fullJson);
      final json = model.toJson();

      expect(json['id'], 'notif-1');
      expect(json['user_id'], 'user-1');
      expect(json['pet_id'], 'pet-1');
      expect(json['pet_name'], 'Buddy');
      expect(json['health_entry_id'], 'entry-1');
      expect(json['organization_id'], 'org-1');
      expect(json['title'], 'Medication Due');
      expect(json['message'], 'Heartgard is due tomorrow');
      // Canonical snake_case, not enum.name ('dueSoon'), which the server's
      // parser would not recognize and which is minified in release builds.
      expect(json['type'], 'due_soon');
      expect(json['is_read'], isFalse);
      expect(json['created_at'], isNotNull);
    });

    test('toJson serializes every type to its canonical API string', () {
      final expected = {
        NotificationType.dueSoon: 'due_soon',
        NotificationType.overdue: 'overdue',
        NotificationType.reminder: 'reminder',
        NotificationType.completed: 'completed',
        NotificationType.general: 'general',
      };
      for (final entry in expected.entries) {
        expect(NotificationModel.typeToApi(entry.key), entry.value);
        final restored = NotificationModel.fromJson({
          ...fullJson,
          'type': entry.value,
        });
        expect(restored.type, entry.key);
      }
    });

    test('toJson includes null optional fields', () {
      final json = {
        'id': 'notif-2',
        'user_id': 'user-1',
        'title': 'Test',
        'message': 'Msg',
        'type': 'general',
        'is_read': true,
        'created_at': '2025-01-01T00:00:00.000Z',
      };
      final model = NotificationModel.fromJson(json);
      final output = model.toJson();
      expect(output['pet_id'], isNull);
      expect(output['pet_name'], isNull);
      expect(output['health_entry_id'], isNull);
      expect(output['organization_id'], isNull);
    });

    test('toJson round-trips through fromJson', () {
      final original = NotificationModel.fromJson(fullJson);
      final json = original.toJson();
      final restored = NotificationModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.petId, original.petId);
      expect(restored.petName, original.petName);
      expect(restored.healthEntryId, original.healthEntryId);
      expect(restored.organizationId, original.organizationId);
      expect(restored.title, original.title);
      expect(restored.message, original.message);
      expect(restored.isRead, original.isRead);
    });

    test('is an AppNotification', () {
      final model = NotificationModel.fromJson(fullJson);
      expect(model, isA<AppNotification>());
    });
  });

  group('NotificationPreferencesModel', () {
    final fullJson = {
      'email_reminders_enabled': true,
      'reminder_days_before': 3,
      'notify_overdue': true,
      'notify_due_soon': false,
      'notify_completed': true,
      'muted_pet_ids': ['pet-1', 'pet-2'],
    };

    test('fromJson parses all fields correctly', () {
      final model = NotificationPreferencesModel.fromJson(fullJson);

      expect(model.emailRemindersEnabled, isTrue);
      expect(model.reminderDaysBefore, 3);
      expect(model.notifyOverdue, isTrue);
      expect(model.notifyDueSoon, isFalse);
      expect(model.notifyCompleted, isTrue);
      expect(model.mutedPetIds, ['pet-1', 'pet-2']);
    });

    test('fromJson handles missing fields with defaults', () {
      final model = NotificationPreferencesModel.fromJson(<String, dynamic>{});

      expect(model.emailRemindersEnabled, isFalse);
      expect(model.reminderDaysBefore, 1);
      expect(model.notifyOverdue, isTrue);
      expect(model.notifyDueSoon, isTrue);
      expect(model.notifyCompleted, isTrue);
      expect(model.mutedPetIds, isEmpty);
    });

    test('fromJson handles null muted_pet_ids', () {
      final json = {...fullJson, 'muted_pet_ids': null};
      final model = NotificationPreferencesModel.fromJson(json);
      expect(model.mutedPetIds, isEmpty);
    });

    test('fromJson handles int muted_pet_ids elements', () {
      final json = {
        ...fullJson,
        'muted_pet_ids': [1, 2, 3],
      };
      final model = NotificationPreferencesModel.fromJson(json);
      expect(model.mutedPetIds, ['1', '2', '3']);
    });

    test('toJson produces correct map', () {
      final model = NotificationPreferencesModel.fromJson(fullJson);
      final json = model.toJson();

      expect(json['email_reminders_enabled'], isTrue);
      expect(json['reminder_days_before'], 3);
      expect(json['notify_overdue'], isTrue);
      expect(json['notify_due_soon'], isFalse);
      expect(json['notify_completed'], isTrue);
      expect(json['muted_pet_ids'], ['pet-1', 'pet-2']);
    });

    test('toJson round-trips through fromJson', () {
      final original = NotificationPreferencesModel.fromJson(fullJson);
      final json = original.toJson();
      final restored = NotificationPreferencesModel.fromJson(json);

      expect(restored.emailRemindersEnabled, original.emailRemindersEnabled);
      expect(restored.reminderDaysBefore, original.reminderDaysBefore);
      expect(restored.notifyOverdue, original.notifyOverdue);
      expect(restored.notifyDueSoon, original.notifyDueSoon);
      expect(restored.notifyCompleted, original.notifyCompleted);
      expect(restored.mutedPetIds, original.mutedPetIds);
    });

    test('default constructor has correct defaults', () {
      const model = NotificationPreferencesModel();

      expect(model.emailRemindersEnabled, isFalse);
      expect(model.reminderDaysBefore, 1);
      expect(model.notifyOverdue, isTrue);
      expect(model.notifyDueSoon, isTrue);
      expect(model.notifyCompleted, isTrue);
      expect(model.mutedPetIds, isEmpty);
    });
  });
}
