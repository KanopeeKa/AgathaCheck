import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';
import 'package:pet_profile_app/features/notifications/domain/services/notification_inbox_v2_rules.dart';

AppNotification _n({
  required NotificationKind kind,
  String wireType = 'general',
  bool isRead = false,
  NotificationPriority priority = NotificationPriority.normal,
  DateTime? resolvedAt,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: 'id-$wireType-$isRead',
    userId: 'u1',
    title: 't',
    message: 'm',
    type: NotificationType.general,
    wireType: wireType,
    kind: kind,
    priority: priority,
    resolvedAt: resolvedAt,
    isRead: isRead,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('NotificationInboxV2Rules calm badge', () {
    test('bell number counts needs-response and urgent activity items', () {
      final list = [
        _n(
          kind: NotificationKind.relationship,
          wireType: 'shareInviteReceived',
        ),
        _n(
          kind: NotificationKind.administrative,
          priority: NotificationPriority.urgent,
        ),
        _n(
          kind: NotificationKind.relationship,
          wireType: 'shareInviteAccepted',
          isRead: true,
        ),
      ];
      expect(NotificationInboxV2Rules.bellNumericCount(list), 2);
    });

    test('bell dot when no numeric count but other unread activity exists', () {
      final list = [
        _n(
          kind: NotificationKind.relationship,
          wireType: 'ownershipTransferCompleted',
        ),
      ];
      expect(NotificationInboxV2Rules.bellNumericCount(list), 0);
      expect(NotificationInboxV2Rules.bellShowDot(list), true);
    });

    test('suggestions unread triggers dot without number', () {
      final list = [_n(kind: NotificationKind.suggestion)];
      expect(NotificationInboxV2Rules.bellNumericCount(list), 0);
      expect(NotificationInboxV2Rules.bellShowDot(list), true);
    });
    test('needs-response invite counts when already read', () {
      final list = [
        _n(
          kind: NotificationKind.relationship,
          wireType: 'shareInviteReceived',
          isRead: true,
        ),
      ];
      expect(NotificationInboxV2Rules.needsResponse(list.first), isTrue);
      expect(NotificationInboxV2Rules.bellNumericCount(list), 1);
    });

    test('account password changed within 7 days needs response', () {
      final list = [
        _n(
          kind: NotificationKind.account,
          wireType: 'accountPasswordChanged',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      expect(NotificationInboxV2Rules.bellNumericCount(list), 1);
    });
  });
}
