import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';

void main() {
  group('defaultKindForNotificationType', () {
    test('maps every NotificationType to care', () {
      for (final type in NotificationType.values) {
        expect(defaultKindForNotificationType(type), NotificationKind.care);
      }
    });
  });
}
