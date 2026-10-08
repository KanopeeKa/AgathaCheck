import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/widgets/notification_suggestion_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
  testWidgets('For you suggestion card shows Agatha chrome and title', (
    tester,
  ) async {
    final notification = AppNotification(
      id: 'n-1',
      userId: 'u-1',
      petId: 'pet-1',
      title: 'Weight check rhythm',
      message: 'Based on recent entries',
      type: NotificationType.general,
      wireType: 'suggestionWeightTrend',
      kind: NotificationKind.suggestion,
      isRead: false,
      createdAt: DateTime(2026, 1, 1),
      suggestionState: 'new',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            () => TestNotificationsNotifier(const []),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NotificationSuggestionCard(
              notification: notification,
              onOpenPet: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(
      tester.element(find.byType(NotificationSuggestionCard)),
    )!;
    expect(find.text(l.careSuggestionTitle), findsOneWidget);
    expect(find.text('Weight check rhythm'), findsOneWidget);

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, AppColorTokens.agathaMessageSurface);
  });
}
