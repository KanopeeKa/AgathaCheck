import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
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
}
