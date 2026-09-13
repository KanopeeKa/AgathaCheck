import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/care_progression_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_manage_events_screen.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/manage_events_filters.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _TestHealthEntriesNotifier extends HealthEntriesNotifier {
  _TestHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

Future<List<HealthHistoryEntry>> _historyFor(Ref ref, String entryId) async =>
    [];

void main() {
  const pet = Pet(id: 'pet-1', name: 'Rex', species: 'Dog', breed: 'Mix');

  final openMedication = HealthEntry(
    id: 'entry-open-med',
    petId: 'pet-1',
    name: 'Heartgard',
    type: HealthEntryType.medication,
    dosage: '1 tablet',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().add(const Duration(days: 3)),
    remindDaysBefore: 7,
  );

  final overduePreventive = HealthEntry(
    id: 'entry-overdue',
    petId: 'pet-1',
    name: 'Flea treatment',
    type: HealthEntryType.preventive,
    dosage: '',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().subtract(const Duration(days: 2)),
    remindDaysBefore: 7,
  );

  final allEntries = [openMedication, overduePreventive];

  Widget buildScreen({List<HealthEntry>? entries}) {
    final router = GoRouter(
      initialLocation: '/pet/pet-1/events',
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) =>
              const Scaffold(body: Text('Pet profile')),
        ),
        GoRoute(
          path: '/pet/:petId/events',
          builder: (context, state) =>
              PetManageEventsScreen(petId: state.pathParameters['petId']!),
        ),
        GoRoute(
          path: '/pet/:petId/health/add',
          builder: (context, state) =>
              const Scaffold(body: Text('Add health entry')),
        ),
        GoRoute(
          path: '/pet/:petId/events/:entryId',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('View ${state.pathParameters['entryId']}'),
            ),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
        healthEntriesNotifierProvider.overrideWith(
          () => _TestHealthEntriesNotifier(entries ?? allEntries),
        ),
        entryHistoryProvider.overrideWith(_historyFor),
        petCareEstablishmentsProvider.overrideWith((ref, petId) async => []),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        apiBaseUrlProvider.overrideWithValue('http://test.local'),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('filterAndSortManageEvents', () {
    test('sorts open entries before closed and by next due date', () {
      final closedRecurring = HealthEntry(
        id: 'entry-closed',
        petId: 'pet-1',
        name: 'Dewormer',
        type: HealthEntryType.preventive,
        frequency: HealthFrequency.monthly,
        startDate: DateTime(2025, 1, 1),
        nextDueDate: DateTime(2025, 8, 1),
        repeatEndDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final histories = <String, List<HealthHistoryEntry>>{};

      final sorted = filterAndSortManageEvents(
        [...allEntries, closedRecurring],
        const ManageEventsFilters(),
        histories,
      );

      expect(sorted.first.id, 'entry-overdue');
      expect(sorted.last.id, 'entry-closed');
    });
  });

  testWidgets('shows All care list with temporal groups', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Manage events'), findsOneWidget);
    expect(find.byKey(const Key('all_care_list')), findsOneWidget);
    expect(find.byKey(const Key('pet_care_action_entry-overdue')), findsOneWidget);
    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.byKey(const Key('pet_manage_events_collection_filter_bar')), findsNothing);
  });

  testWidgets('care action row navigates to view entry', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Heartgard'));
    await tester.pumpAndSettle();

    expect(find.text('View entry-open-med'), findsOneWidget);
  });

  testWidgets('add app bar button navigates to unified health entry form', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_events_add_app_bar')));
    await tester.pumpAndSettle();

    expect(find.text('Add health entry'), findsOneWidget);
  });

  testWidgets('back navigates to pet profile', (tester) async {
    final router = GoRouter(
      initialLocation: '/pet/pet-1',
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  context.push('/pet/${state.pathParameters['petId']}/events'),
              child: const Text('Open manage events'),
            ),
          ),
        ),
        GoRoute(
          path: '/pet/:petId/events',
          builder: (context, state) =>
              PetManageEventsScreen(petId: state.pathParameters['petId']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
          healthEntriesNotifierProvider.overrideWith(
            () => _TestHealthEntriesNotifier(allEntries),
          ),
          entryHistoryProvider.overrideWith(_historyFor),
          petCareEstablishmentsProvider.overrideWith((ref, petId) async => []),
          combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open manage events'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('manage_events_add_app_bar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('experience_back_button')));
    await tester.pumpAndSettle();

    expect(find.text('Open manage events'), findsOneWidget);
  });
}
