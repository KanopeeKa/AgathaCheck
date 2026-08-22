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
}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    title: title,
    message: '$title message',
    type: NotificationType.general,
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
          const NotificationPreferences(),
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

void main() {
  testWidgets(
    'Organisation filter keeps administrative updates and pins urgent work',
    (tester) async {
      await tester.pumpWidget(
        _panel([
          _notification(
            id: 'care',
            title: 'Care reminder',
            kind: NotificationKind.care,
          ),
          _notification(
            id: 'admin',
            title: 'Standard organisation update',
            kind: NotificationKind.administrative,
          ),
          _notification(
            id: 'urgent',
            title: 'Urgent organisation update',
            kind: NotificationKind.administrative,
            priority: NotificationPriority.urgent,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Organisation'));
      await tester.pumpAndSettle();

      expect(find.text('Care reminder'), findsNothing);
      expect(find.text('Standard organisation update'), findsOneWidget);
      expect(find.text('Urgent organisation update'), findsOneWidget);
      expect(find.text('Action needed'), findsNWidgets(2));
      expect(find.text('Urgent'), findsAtLeastNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Urgent organisation update')).dy,
        lessThan(
          tester.getTopLeft(find.text('Standard organisation update')).dy,
        ),
      );
    },
  );
}
