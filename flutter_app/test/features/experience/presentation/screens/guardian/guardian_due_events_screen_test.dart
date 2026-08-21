import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_due_events_screen.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

class _TestHealthEntriesNotifier extends HealthEntriesNotifier {
  _TestHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

Future<List<HealthHistoryEntry>> _historyFor(Ref ref, String entryId) async =>
    [];

void main() {
  const ownedPet = Pet(id: 'pet-owned', name: 'Rex', species: 'Dog', breed: '');
  const fosterPet = Pet(
    id: 'pet-foster',
    name: 'Luna',
    species: 'Cat',
    breed: '',
    isFoster: true,
  );
  const sharedPet = Pet(
    id: 'pet-shared',
    name: 'Milo',
    species: 'Dog',
    breed: '',
    isShared: true,
  );

  final ownedEntry = HealthEntry(
    id: 'entry-owned',
    petId: 'pet-owned',
    name: 'Heartgard',
    type: HealthEntryType.medication,
    dosage: '1 tablet',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().add(const Duration(days: 3)),
  );

  final fosterEntry = HealthEntry(
    id: 'entry-foster',
    petId: 'pet-foster',
    name: 'Flea treatment',
    type: HealthEntryType.preventive,
    dosage: '',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().subtract(const Duration(days: 2)),
  );

  final sharedEntry = HealthEntry(
    id: 'entry-shared',
    petId: 'pet-shared',
    name: 'Grooming',
    type: HealthEntryType.other,
    dosage: 'Full groom',
    frequency: HealthFrequency.once,
    startDate: DateTime(2025, 1, 1),
    completedOn: DateTime(2025, 3, 1),
    nextDueDate: DateTime(9999, 12, 31),
  );

  final allEntries = [ownedEntry, fosterEntry, sharedEntry];
  final shellPets = [ownedPet, fosterPet, sharedPet];

  Widget buildScreen({List<HealthEntry>? entries}) {
    final router = GoRouter(
      initialLocation: '/g/events',
      routes: [
        GoRoute(
          path: '/g/events',
          builder: (context, state) => ExperienceShellScaffold(
            experience: AppExperience.guardian,
            currentLocation: state.uri.path,
            screenTitle: 'Events',
            backPath: '/g/home',
            contextualActions: [
              IconButton(
                key: const Key('global_events_add_app_bar'),
                onPressed: () => context.push('/health/add'),
                icon: const Icon(Icons.add),
              ),
            ],
            child: const GuardianDueEventsScreen(),
          ),
        ),
        GoRoute(
          path: '/health/add',
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
        petListProvider.overrideWith(() => TestPetListNotifier(shellPets)),
        healthEntriesNotifierProvider.overrideWith(
          () => _TestHealthEntriesNotifier(entries ?? allEntries),
        ),
        entryHistoryProvider.overrideWith(_historyFor),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('guardianGlobalEventsPets', () {
    test('my pets cohort includes owned and shared pets', () {
      final pets = guardianGlobalEventsPets(
        shellPets,
        const GuardianGlobalEventsFilters(
          cohorts: {GuardianEventsCohortFilter.myPets},
        ),
      );

      expect(pets.map((pet) => pet.id), ['pet-owned', 'pet-shared']);
    });

    test('foster cohort includes only foster pets', () {
      final pets = guardianGlobalEventsPets(
        shellPets,
        const GuardianGlobalEventsFilters(
          cohorts: {GuardianEventsCohortFilter.fosterPets},
        ),
      );

      expect(pets, [fosterPet]);
    });

    test('pet filter narrows cohort selection', () {
      final pets = guardianGlobalEventsPets(
        shellPets,
        const GuardianGlobalEventsFilters(petIds: {'pet-owned'}),
      );

      expect(pets, [ownedPet]);
    });

    test('multi-select cohorts combine with OR', () {
      final pets = guardianGlobalEventsPets(
        shellPets,
        const GuardianGlobalEventsFilters(
          cohorts: {
            GuardianEventsCohortFilter.myPets,
            GuardianEventsCohortFilter.fosterPets,
          },
        ),
      );

      expect(
        pets.map((pet) => pet.id),
        containsAll(['pet-owned', 'pet-shared', 'pet-foster']),
      );
    });
  });

  testWidgets('shows unified Events list without tabs', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsNWidgets(2));
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Grooming'), findsOneWidget);
    expect(find.byKey(const Key('global_events_add_app_bar')), findsOneWidget);
  });

  testWidgets('add app bar button navigates to unified health entry form', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
    await tester.pumpAndSettle();

    expect(find.text('Add health entry'), findsOneWidget);
  });

  testWidgets('EventListCard navigates to view entry', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Heartgard'));
    await tester.pumpAndSettle();

    expect(find.text('View entry-owned'), findsOneWidget);
  });

  testWidgets('due/overdue filter hides non-due entries', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_events_status_dueOverdue')));
    await tester.pumpAndSettle();

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);
    expect(find.text('Grooming'), findsNothing);
  });

  testWidgets('my pets cohort hides foster pet entries', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_cohort_myPets')));
    await tester.pumpAndSettle();

    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Grooming'), findsOneWidget);
    expect(find.text('Flea treatment'), findsNothing);
  });

  testWidgets('foster cohort hides owned pet entries', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_cohort_fosterPets')));
    await tester.pumpAndSettle();

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);
    expect(find.text('Grooming'), findsNothing);
  });

  testWidgets('multi-select pet filters combine with OR', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_pet_pet-owned')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global_events_pet_pet-foster')));
    await tester.pumpAndSettle();

    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Grooming'), findsNothing);
  });
}
