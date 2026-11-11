import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';
import 'package:pet_profile_app/features/notifications/domain/services/notification_inbox_v2_rules.dart';
import 'package:pet_profile_app/features/notifications/presentation/utils/mark_all_read_eligibility.dart';

AppNotification _n({
  required NotificationKind kind,
  bool isRead = false,
  String? suggestionState,
}) {
  return AppNotification(
    id: 'id-$kind-$isRead',
    userId: 'u1',
    title: 't',
    message: 'm',
    type: NotificationType.general,
    kind: kind,
    isRead: isRead,
    suggestionState: suggestionState,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('MarkAllReadEligibility', () {
    test('disabled while loading', () {
      expect(
        MarkAllReadEligibility.isEligible(
          isLoading: true,
          notifications: [_n(kind: NotificationKind.relationship)],
          tab: NotificationInboxTab.activity,
        ),
        isFalse,
      );
    });

    test('activity tab needs unread activity items', () {
      final allRead = [_n(kind: NotificationKind.relationship, isRead: true)];
      expect(
        MarkAllReadEligibility.isEligible(
          isLoading: false,
          notifications: allRead,
          tab: NotificationInboxTab.activity,
        ),
        isFalse,
      );

      final unread = [_n(kind: NotificationKind.administrative)];
      expect(
        MarkAllReadEligibility.isEligible(
          isLoading: false,
          notifications: unread,
          tab: NotificationInboxTab.activity,
        ),
        isTrue,
      );
    });

    test('for you tab uses suggestion unread state', () {
      final readSuggestion = [
        _n(
          kind: NotificationKind.suggestion,
          isRead: true,
          suggestionState: 'seen',
        ),
      ];
      expect(
        MarkAllReadEligibility.isEligible(
          isLoading: false,
          notifications: readSuggestion,
          tab: NotificationInboxTab.forYou,
        ),
        isFalse,
      );

      final newSuggestion = [
        _n(kind: NotificationKind.suggestion, suggestionState: 'new'),
      ];
      expect(
        MarkAllReadEligibility.isEligible(
          isLoading: false,
          notifications: newSuggestion,
          tab: NotificationInboxTab.forYou,
        ),
        isTrue,
      );
    });

    test('ignores items outside the selected tab', () {
      expect(
        MarkAllReadEligibility.isEligible(
          isLoading: false,
          notifications: [_n(kind: NotificationKind.suggestion)],
          tab: NotificationInboxTab.activity,
        ),
        isFalse,
      );
    });
  });
}
