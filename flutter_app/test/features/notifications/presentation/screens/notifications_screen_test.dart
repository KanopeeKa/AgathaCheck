import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_preferences.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_scope.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

AppNotification _sampleNotification({
  required String id,
  required String title,
  required String message,
  bool isRead = false,
  String? petId,
  String? petName,
  String? healthEntryId,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    petId: petId,
    petName: petName,
    healthEntryId: healthEntryId,
    title: title,
    message: message,
    type: NotificationType.dueSoon,
    isRead: isRead,
    createdAt: createdAt ?? DateTime.now(),
  );
}

Widget _wrap({
  required Widget child,
  List<AppNotification> notifications = const [],
  List<String> mutedPetIds = const [],
  List<Pet> pets = const [],
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      notificationsProvider.overrideWith(
        () => TestNotificationsNotifier(notifications),
      ),
      notificationPreferencesProvider.overrideWith(
        () => TestNotificationPreferencesNotifier(
          NotificationPreferences(mutedPetIds: mutedPetIds),
        ),
      ),
      petListProvider.overrideWith(() => TestPetListNotifier(pets)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => child),
          GoRoute(
            path: '/notifications/settings',
            builder: (context, state) =>
                const Scaffold(body: Text('Notification settings')),
          ),
          GoRoute(
            path: '/pet/:id',
            builder: (context, state) =>
                Scaffold(body: Text('Pet ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/pet/:petId/events/:entryId',
            builder: (context, state) => Scaffold(
              body: Text(
                'View ${state.pathParameters['entryId']} for ${state.pathParameters['petId']}',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('shows empty state when there are no notifications', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(child: const NotificationsScreen()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NotificationsScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.noNotifications), findsOneWidget);
    expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);
  });

  testWidgets('shows notification titles grouped by date', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      _wrap(
        child: const NotificationsScreen(),
        notifications: [
          _sampleNotification(
            id: 'n1',
            title: 'Heartworm due',
            message: 'Give medication today',
            petId: 'pet-1',
            petName: 'Bella',
            createdAt: now,
          ),
          _sampleNotification(
            id: 'n2',
            title: 'Vaccination due',
            message: 'Book a vet visit',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heartworm due'), findsOneWidget);
    expect(find.text('Vaccination due'), findsOneWidget);
    expect(find.text('Bella'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('hides notifications for muted pets', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const NotificationsScreen(),
        notifications: [
          _sampleNotification(
            id: 'n1',
            title: 'Muted pet alert',
            message: 'Should be hidden',
            petId: 'muted-pet',
            petName: 'Quiet',
          ),
          _sampleNotification(
            id: 'n2',
            title: 'Visible alert',
            message: 'Should be shown',
            petId: 'active-pet',
            petName: 'Active',
          ),
        ],
        mutedPetIds: const ['muted-pet'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Muted pet alert'), findsNothing);
    expect(find.text('Visible alert'), findsOneWidget);
  });

  testWidgets('mark all read button marks notifications as read', (
    tester,
  ) async {
    late TestNotificationsNotifier notifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          notificationsProvider.overrideWith(() {
            notifier = TestNotificationsNotifier([
              _sampleNotification(
                id: 'n1',
                title: 'Unread alert',
                message: 'Due today',
              ),
            ]);
            return notifier;
          }),
          notificationPreferencesProvider.overrideWith(
            () => TestNotificationPreferencesNotifier(
              const NotificationPreferences(),
            ),
          ),
          petListProvider.overrideWith(() => TestPetListNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mark_all_read_button')));
    await tester.pumpAndSettle();

    expect(notifier.markAllAsReadCalled, isTrue);
  });

  testWidgets('tapping due event notification navigates to view entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        child: const NotificationsScreen(),
        notifications: [
          _sampleNotification(
            id: 'n1',
            title: 'Vaccination overdue',
            message: 'Due yesterday',
            petId: 'pet-1',
            petName: 'Bella',
            healthEntryId: 'entry-1',
            isRead: true,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vaccination overdue'));
    await tester.pumpAndSettle();

    expect(find.text('View entry-1 for pet-1'), findsOneWidget);
  });

  testWidgets('org scope hides owned pet notifications', (tester) async {
    const owned = Pet(id: 'p-owned', name: 'Bella', species: 'Dog');
    const foster = Pet(
      id: 'p-foster',
      name: 'Rex',
      species: 'Dog',
      isFoster: true,
      organizationId: 'org-1',
      organizationName: 'Shelter',
    );

    await tester.pumpWidget(
      _wrap(
        child: const NotificationsScreen(
          backPath: '/o/home',
          scope: NotificationScope.organization,
        ),
        pets: [owned, foster],
        notifications: [
          _sampleNotification(
            id: 'n-owned',
            title: 'Bella overdue',
            message: 'Due today',
            petId: 'p-owned',
            petName: 'Bella',
          ),
          _sampleNotification(
            id: 'n-foster',
            title: 'Rex overdue',
            message: 'Due today',
            petId: 'p-foster',
            petName: 'Rex',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bella overdue'), findsNothing);
    expect(find.text('Rex overdue'), findsOneWidget);
  });
}
