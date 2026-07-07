import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_preferences.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

Widget _wrap({
  required NotificationPreferences preferences,
  List<Pet> pets = const [],
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      notificationPreferencesProvider.overrideWith(
        () => TestNotificationPreferencesNotifier(preferences),
      ),
      petListProvider.overrideWith(() => TestPetListNotifier(pets)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationSettingsScreen(),
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('renders in-app notification toggles', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(preferences: const NotificationPreferences()),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NotificationSettingsScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.overdueAlerts), findsOneWidget);
    expect(find.text(l10n.dueSoonAlerts), findsOneWidget);
    expect(find.text(l10n.completedAlerts), findsOneWidget);
    expect(find.text(l10n.saveSettings), findsOneWidget);
  });

  testWidgets('shows muted pets from the pet list', (tester) async {
    await tester.pumpWidget(
      _wrap(
        preferences: const NotificationPreferences(mutedPetIds: ['bella']),
        pets: const [
          Pet(
            id: 'bella',
            name: 'Bella',
            species: 'Dog',
            breed: '',
            colorValue: 0xFF7E57C2,
            passedAway: false,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bella'), findsOneWidget);
    expect(find.text('Muted'), findsOneWidget);
  });

  testWidgets('save button persists updated preferences', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    late TestNotificationPreferencesNotifier notifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          notificationPreferencesProvider.overrideWith(() {
            notifier = TestNotificationPreferencesNotifier(
              const NotificationPreferences(notifyCompleted: true),
            );
            return notifier;
          }),
          petListProvider.overrideWith(() => TestPetListNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completed Alerts'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save Settings'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Settings'));
    await tester.pumpAndSettle();

    expect(notifier.lastSaved?.notifyCompleted, isFalse);
  });
}
