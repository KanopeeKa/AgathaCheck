import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';
import 'package:pet_profile_app/features/notifications/domain/services/notification_inline_action_support.dart';

void main() {
  test('share invite pending rows support inline actions', () {
    final n = AppNotification(
      id: '1',
      userId: 'u',
      title: 'Invite',
      message: 'msg',
      type: NotificationType.general,
      wireType: 'shareInviteReceived',
      kind: NotificationKind.relationship,
      isRead: false,
      createdAt: DateTime(2026, 1, 1),
      healthEntryId: 'code',
    );
    expect(NotificationInlineActionSupport.supportsInlineActions(n), isTrue);
  });

  test('account new sign-in rows support inline actions', () {
    final n = AppNotification(
      id: '2',
      userId: 'u',
      title: 'Sign-in',
      message: 'Chrome on Windows',
      type: NotificationType.general,
      wireType: 'accountNewSignIn',
      kind: NotificationKind.account,
      isRead: false,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(NotificationInlineActionSupport.supportsInlineActions(n), isTrue);
    expect(
      NotificationInlineActionSupport.kindFor(n),
      NotificationInlineActionKind.accountNewSignIn,
    );
  });

  test('account password changed within 7 days supports secure inline action', () {
    final n = AppNotification(
      id: '3',
      userId: 'u',
      title: 'Password',
      message: 'changed',
      type: NotificationType.general,
      wireType: 'accountPasswordChanged',
      kind: NotificationKind.account,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    expect(NotificationInlineActionSupport.supportsInlineActions(n), isTrue);
    expect(
      NotificationInlineActionSupport.kindFor(n),
      NotificationInlineActionKind.accountPasswordChanged,
    );
  });

  test('account password changed after 7 days has no inline actions', () {
    final n = AppNotification(
      id: '4',
      userId: 'u',
      title: 'Password',
      message: 'changed',
      type: NotificationType.general,
      wireType: 'accountPasswordChanged',
      kind: NotificationKind.account,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    );
    expect(NotificationInlineActionSupport.supportsInlineActions(n), isFalse);
  });

  test('read rows do not show inline actions', () {
    final n = AppNotification(
      id: '1',
      userId: 'u',
      title: 'Invite',
      message: 'msg',
      type: NotificationType.general,
      wireType: 'shareInviteReceived',
      kind: NotificationKind.relationship,
      isRead: true,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(NotificationInlineActionSupport.supportsInlineActions(n), isFalse);
  });
}
