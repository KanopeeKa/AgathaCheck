import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_event_row.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/manage_events_filters.dart';

import 'pet_care_events_test_helpers.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _ownedPet = testOwnedPet;
const _fosterPet = testFosterPet;
final _shellPets = testAllShellPets;

final _ownedEntry = HealthEntry(
  id: 'entry-owned',
  petId: 'pet-owned',
  name: 'Heartgard',
  type: HealthEntryType.medication,
  dosage: '1 tablet',
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime.now().add(const Duration(days: 3)),
);

final _fosterEntry = HealthEntry(
  id: 'entry-foster',
  petId: 'pet-foster',
  name: 'Flea treatment',
  type: HealthEntryType.preventive,
  dosage: '',
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime.now().subtract(const Duration(days: 2)),
);

void main() {
  // ---------------------------------------------------------------------------
  // Pure-logic tests
  // ---------------------------------------------------------------------------

  group('guardianGlobalEventsPets', () {
    test('my pets cohort includes owned and shared pets', () {
      final pets = guardianGlobalEventsPets(
        _shellPets,
        const PetCareGlobalEventsFilters(
          cohorts: {PetCareEventsCohortFilter.myPets},
        ),
      );
      expect(pets.map((p) => p.id), ['pet-owned', 'pet-shared']);
    });

    test('foster cohort includes only foster pets', () {
      final pets = guardianGlobalEventsPets(
        _shellPets,
        const PetCareGlobalEventsFilters(
          cohorts: {PetCareEventsCohortFilter.fosterPets},
        ),
      );
      expect(pets, [_fosterPet]);
    });

    test('pet filter narrows by id', () {
      final pets = guardianGlobalEventsPets(
        _shellPets,
        const PetCareGlobalEventsFilters(petIds: {'pet-owned'}),
      );
      expect(pets, [_ownedPet]);
    });

    test('multi-select cohorts combine with OR', () {
      final pets = guardianGlobalEventsPets(
        _shellPets,
        const PetCareGlobalEventsFilters(
          cohorts: {
            PetCareEventsCohortFilter.myPets,
            PetCareEventsCohortFilter.fosterPets,
          },
        ),
      );
      expect(
        pets.map((p) => p.id),
        containsAll(['pet-owned', 'pet-shared', 'pet-foster']),
      );
    });

    test('preserves provider order while applying event predicates', () {
      final entries = [_fosterEntry, _ownedEntry];
      final visible = filterPetCareGlobalEvents(
        entries,
        _shellPets,
        const PetCareGlobalEventsFilters(),
        const {},
      );

      // Default status filter is due/overdue — only the overdue foster entry.
      expect(visible.map((entry) => entry.id), ['entry-foster']);
    });

    test('all status filter includes non-due open entries', () {
      final entries = [_fosterEntry, _ownedEntry];
      final visible = filterPetCareGlobalEvents(
        entries,
        _shellPets,
        const PetCareGlobalEventsFilters(
          eventFilters: ManageEventsFilters(statuses: {}),
        ),
        const {},
      );

      expect(visible.map((entry) => entry.id), ['entry-foster', 'entry-owned']);
    });
  });

  // ---------------------------------------------------------------------------
  // Screen-level widget tests (default ~800px → desktop layout)
  // ---------------------------------------------------------------------------

  testWidgets('shows unified Events list without tabs', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsNWidgets(2));
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);
    expect(find.text('Grooming'), findsNothing);
    expect(find.byKey(const Key('global_events_add_app_bar')), findsOneWidget);
  });

  testWidgets('add app bar button opens Events and Weight entry picker sheet', (
    tester,
  ) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
    await tester.pumpAndSettle();

    expect(find.text('Add an event'), findsOneWidget);
    expect(find.byIcon(Icons.medical_services_outlined), findsOneWidget);
    expect(find.text('Events'), findsWidgets);
    expect(find.text('Weight entry'), findsOneWidget);
  });

  testWidgets('add picker: tapping Health routes to /health/add', (
    tester,
  ) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.medical_services_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Add health entry'), findsOneWidget);
  });

  testWidgets('row tap navigates to view entry', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flea treatment'));
    await tester.pumpAndSettle();

    expect(find.text('View entry-foster'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Filter / cohort chip tests
  // ---------------------------------------------------------------------------

  testWidgets('due/overdue filter hides non-due entries', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);

    await tapCollectionFilterChoice(
      tester,
      dimensionId: 'status',
      choiceId: 'all',
    );

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsOneWidget);
  });

  testWidgets('my pets cohort hides foster entries', (tester) async {
    await tester.pumpWidget(
      buildEventsScreen(
        entries: [
          _ownedEntry.copyWith(nextDueDate: DateTime.now()),
          _fosterEntry,
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tapCollectionFilterChoice(
      tester,
      dimensionId: 'cohort',
      choiceId: 'myPets',
      inMore: true,
    );

    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Flea treatment'), findsNothing);
  });

  testWidgets('foster cohort hides owned entries', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    await tapCollectionFilterChoice(
      tester,
      dimensionId: 'cohort',
      choiceId: 'fosterPets',
      inMore: true,
    );

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);
  });

  testWidgets('multi-select pet filters combine with OR', (tester) async {
    await tester.pumpWidget(
      buildEventsScreen(
        entries: [
          _ownedEntry.copyWith(nextDueDate: DateTime.now()),
          _fosterEntry,
          HealthEntry(
            id: 'entry-shared',
            petId: 'pet-shared',
            name: 'Grooming',
            type: HealthEntryType.other,
            dosage: 'Full groom',
            frequency: HealthFrequency.once,
            startDate: DateTime(2025, 1, 1),
            completedOn: DateTime(2025, 3, 1),
            nextDueDate: DateTime(9999, 12, 31),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tapCollectionFilterChoice(
      tester,
      dimensionId: 'pet',
      choiceId: 'pet:pet-owned',
    );
    await tapCollectionFilterChoice(
      tester,
      dimensionId: 'pet',
      choiceId: 'pet:pet-foster',
    );

    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Grooming'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Pet-provider error → localized retry button
  // ---------------------------------------------------------------------------

  testWidgets(
    'pet-provider error shows localized retry, not raw error string',
    (tester) async {
      await tester.pumpWidget(buildScreenWithPetError());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pet_load_error_retry')), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      // Must not expose raw exception text to the user.
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.textContaining('pets unavailable'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // Care-list provider error state
  // ---------------------------------------------------------------------------

  testWidgets('care-list error shows retry, not empty state', (tester) async {
    await tester.pumpWidget(
      buildListScreen(
        pets: const [_ownedPet],
        notifierFactory: TestErrorEntriesNotifier.new,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byKey(const Key('global_events_retry')), findsOneWidget);
    expect(find.text('No entries yet'), findsNothing);
  });

  testWidgets('terminal care error replaces loaded list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final notifier = TestMutableEntriesNotifier([
      _ownedEntry.copyWith(nextDueDate: DateTime.now()),
    ]);
    await tester.pumpWidget(
      buildListScreen(pets: const [_ownedPet], notifierFactory: () => notifier),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('global_events_row_entry-owned')),
      findsOneWidget,
    );

    notifier.publishTerminalError();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byKey(const Key('global_events_retry')), findsOneWidget);
    expect(
      find.byKey(const Key('global_events_row_entry-owned')),
      findsNothing,
    );
    expect(find.text('No entries yet'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Layout breakpoint tests
  // ---------------------------------------------------------------------------

  testWidgets('uses CareEventRow at all viewport widths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildListScreen(
        pets: const [_ownedPet],
        notifierFactory: () => TestFixedEntriesNotifier([
          _ownedEntry.copyWith(nextDueDate: DateTime.now()),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global_events_list')), findsOneWidget);
    expect(find.byType(CareEventRow), findsOneWidget);
  });
}
