import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_preferences.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/widgets/notification_panel.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

AppNotification _notification({
  required String id,
  required String title,
  required NotificationKind kind,
  NotificationPriority priority = NotificationPriority.normal,
  DateTime? createdAt,
  String wireType = 'general',
}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    title: title,
    message: '$title message',
    type: NotificationType.general,
    wireType: wireType,
    kind: kind,
    priority: priority,
    isRead: false,
    createdAt: createdAt ?? DateTime.now(),
  );
}

Widget _panel(List<AppNotification> notifications) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      notificationsProvider.overrideWith(
        () => TestNotificationsNotifier(notifications),
      ),
      notificationPreferencesProvider.overrideWith(
        () => TestNotificationPreferencesNotifier(
          NotificationPreferences(v2ExplainerDismissedAt: _dismissedExplainer),
        ),
      ),
      petListProvider.overrideWith(() => TestPetListNotifier()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: NotificationPanel()),
    ),
  );
}

final _dismissedExplainer = DateTime.utc(2026, 1, 1);

void main() {
  testWidgets('shows Activity and For you tabs without legacy kind chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      _panel([
        _notification(
          id: 'rel',
          title: 'Invite pending',
          kind: NotificationKind.relationship,
          wireType: 'shareInviteReceived',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NotificationPanel));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.notificationInboxTabActivity), findsOneWidget);
    expect(find.text(l10n.notificationInboxTabForYou), findsOneWidget);
    expect(find.text(l10n.notificationKindAll), findsNothing);
    expect(find.text(l10n.notificationKindOrganisation), findsNothing);
    expect(find.text('Invite pending'), findsOneWidget);
  });

  testWidgets('Activity tab pins urgent administrative items', (tester) async {
    await tester.pumpWidget(
      _panel([
        _notification(
          id: 'urgent',
          title: 'Urgent organisation update',
          kind: NotificationKind.administrative,
          priority: NotificationPriority.urgent,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        _notification(
          id: 'admin',
          title: 'Standard organisation update',
          kind: NotificationKind.administrative,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Urgent organisation update'), findsOneWidget);
    expect(find.text('Standard organisation update'), findsOneWidget);
    expect(find.text('Urgent'), findsAtLeastNWidgets(1));
    expect(
      tester.getTopLeft(find.text('Urgent organisation update')).dy,
      lessThan(tester.getTopLeft(find.text('Standard organisation update')).dy),
    );
  });
}
