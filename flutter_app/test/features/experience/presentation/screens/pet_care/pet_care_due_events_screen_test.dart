import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/screens/widgets/manage_events_filters.dart';

import 'pet_care_events_test_helpers.dart';
import '../../../../../helpers/care_schedule_entries.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _ownedPet = testOwnedPet;
const _fosterPet = testFosterPet;
final _shellPets = testAllShellPets;

final _ownedEntry = scheduledEntry(
  id: 'entry-owned',
  petId: 'pet-owned',
  name: 'Heartgard',
  dueInDays: 30,
);

final _fosterEntry = scheduledEntry(
  id: 'entry-foster',
  petId: 'pet-foster',
  name: 'Flea treatment',
  dueInDays: -2,
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

      expect(visible.map((entry) => entry.id), ['entry-foster', 'entry-owned']);
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

  testWidgets('shows unified All care list without tabs', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    expect(find.text('All care'), findsNWidgets(2));
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

  testWidgets('add picker: tapping Events routes to /care/add', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.medical_services_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Add care entry'), findsOneWidget);
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

  testWidgets('agenda surfaces non-due open entries without status filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildEventsScreen(entries: [_fosterEntry, _ownedEntry]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.byKey(const Key('care_agenda_upcoming')), findsOneWidget);

    await tester.tap(find.byKey(const Key('care_agenda_upcoming')));
    await tester.pumpAndSettle();
    expect(find.text('Heartgard'), findsOneWidget);
  });

  testWidgets('my pets cohort hides foster entries', (tester) async {
    await tester.pumpWidget(
      buildEventsScreen(
        entries: [
          scheduledEntry(
            id: _ownedEntry.id,
            petId: _ownedEntry.petId,
            name: _ownedEntry.name,
            dueInDays: 0,
          ),
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
          scheduledEntry(
            id: _ownedEntry.id,
            petId: _ownedEntry.petId,
            name: _ownedEntry.name,
            dueInDays: 0,
          ),
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

    await tester.tap(find.byKey(const Key('global_events_pet_pet-owned')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('global_events_pet_pet-foster')));
    await tester.pumpAndSettle();

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
      scheduledEntry(
        id: _ownedEntry.id,
        petId: _ownedEntry.petId,
        name: _ownedEntry.name,
        dueInDays: 0,
      ),
    ]);
    await tester.pumpWidget(
      buildListScreen(pets: const [_ownedPet], notifierFactory: () => notifier),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pet_care_action_entry-owned')),
      findsOneWidget,
    );

    notifier.publishTerminalError();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byKey(const Key('global_events_retry')), findsOneWidget);
    expect(find.byKey(const Key('pet_care_action_entry-owned')), findsNothing);
    expect(find.text('No entries yet'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Layout breakpoint tests
  // ---------------------------------------------------------------------------

  testWidgets('planned care uses the agenda', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildListScreen(
        pets: const [_ownedPet],
        notifierFactory: () => TestFixedEntriesNotifier([
          scheduledEntry(id: 'planned', name: 'Planned', petId: _ownedPet.id),
          _ownedEntry,
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_agenda')), findsOneWidget);
    expect(find.byKey(const Key('pet_care_action_planned')), findsOneWidget);
  });

  testWidgets('?pet= deep link preselects pet filter chips', (tester) async {
    await tester.pumpWidget(
      buildEventsScreen(
        initialLocation: '/pc/events?pet=pet-owned',
        entries: [
          scheduledEntry(
            id: _ownedEntry.id,
            petId: _ownedEntry.petId,
            name: _ownedEntry.name,
            dueInDays: 0,
          ),
          _fosterEntry,
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Flea treatment'), findsNothing);

    final fosterChip = find.byKey(const Key('global_events_pet_pet-foster'));
    await tester.tap(fosterChip);
    await tester.pumpAndSettle();

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsOneWidget);
  });

  testWidgets('paused and closed care use collapsible sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildEventsScreen(
        entries: [
          scheduledEntry(
            id: _ownedEntry.id,
            petId: _ownedEntry.petId,
            name: _ownedEntry.name,
            dueInDays: 0,
          ),
          scheduledEntry(
            id: 'paused-entry',
            petId: 'pet-owned',
            name: 'Paused care item',
            dueInDays: 14,
            entryStatus: 'paused',
          ),
          scheduledEntry(
            id: 'closed-entry',
            petId: 'pet-owned',
            name: 'Closed care item',
            dueInDays: 30,
            frequency: HealthFrequency.once,
            entryStatus: 'closed',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('global_events_paused_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('global_events_closed_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('global_events_row_paused-entry')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('global_events_row_closed-entry')),
      findsNothing,
    );
  });

  testWidgets('lifecycle rows render at all viewport widths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildListScreen(
        pets: const [_ownedPet],
        notifierFactory: () => TestFixedEntriesNotifier([
          scheduledEntry(
            id: 'lifecycle-row',
            petId: 'pet-owned',
            name: 'Paused item',
            dueInDays: 30,
            entryStatus: 'paused',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global_events_list')), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('global_events_paused_care'),
      findsOneWidget,
    );
  });
}
