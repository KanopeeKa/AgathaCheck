import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_scope.dart';
import 'package:pet_profile_app/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('renders notification title with list scope', (tester) async {
    final notification = AppNotification(
      id: 'n-1',
      userId: 'user-1',
      title: 'Vaccine due',
      message: 'Annual booster',
      type: NotificationType.reminder,
      isRead: false,
      createdAt: DateTime(2026, 7, 24, 10),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NotificationTile(
              notification: notification,
              listScope: NotificationScope.guardian,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vaccine due'), findsOneWidget);
    expect(find.text('Annual booster'), findsOneWidget);
  });

  testWidgets(
    'keeps unresolved administrative actions distinct from read state',
    (tester) async {
      final notification = AppNotification(
        id: 'admin-urgent',
        userId: 'user-1',
        title: 'Placement needs a response',
        message: 'Review the placement request.',
        type: NotificationType.general,
        kind: NotificationKind.administrative,
        priority: NotificationPriority.urgent,
        isRead: true,
        createdAt: DateTime(2026, 7, 24, 10),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
                listScope: NotificationScope.organization,
                showActionNeeded: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Action needed'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('Unread'), findsNothing);
    },
  );

  testWidgets('shows resolved administrative state and wraps at large text', (
    tester,
  ) async {
    final notification = AppNotification(
      id: 'admin-resolved',
      userId: 'user-1',
      title: 'A long organisation update that must remain readable',
      message:
          'This longer message stays available instead of being clipped when '
          'the user has increased their text size.',
      type: NotificationType.general,
      kind: NotificationKind.administrative,
      resolvedAt: DateTime(2026, 7, 23),
      isRead: false,
      createdAt: DateTime(2026, 7, 24, 10),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
                listScope: NotificationScope.organization,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text(notification.message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
