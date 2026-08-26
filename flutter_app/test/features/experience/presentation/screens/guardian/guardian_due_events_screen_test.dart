import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/mobile_due_event_row.dart';

import 'guardian_events_test_helpers.dart';

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
        const GuardianGlobalEventsFilters(
          cohorts: {GuardianEventsCohortFilter.myPets},
        ),
      );
      expect(pets.map((p) => p.id), ['pet-owned', 'pet-shared']);
    });

    test('foster cohort includes only foster pets', () {
      final pets = guardianGlobalEventsPets(
        _shellPets,
        const GuardianGlobalEventsFilters(
          cohorts: {GuardianEventsCohortFilter.fosterPets},
        ),
      );
      expect(pets, [_fosterPet]);
    });

    test('pet filter narrows by id', () {
      final pets = guardianGlobalEventsPets(
        _shellPets,
        const GuardianGlobalEventsFilters(petIds: {'pet-owned'}),
      );
      expect(pets, [_ownedPet]);
    });

    test('multi-select cohorts combine with OR', () {
      final pets = guardianGlobalEventsPets(
        _shellPets,
        const GuardianGlobalEventsFilters(
          cohorts: {
            GuardianEventsCohortFilter.myPets,
            GuardianEventsCohortFilter.fosterPets,
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
      final visible = filterGuardianGlobalEvents(
        entries,
        _shellPets,
        const GuardianGlobalEventsFilters(),
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
    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Flea treatment'), findsOneWidget);
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

    await tester.tap(find.text('Heartgard'));
    await tester.pumpAndSettle();

    expect(find.text('View entry-owned'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Filter / cohort chip tests
  // ---------------------------------------------------------------------------

  testWidgets('due/overdue filter hides non-due entries', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_events_status_dueOverdue')));
    await tester.pumpAndSettle();

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);
  });

  testWidgets('my pets cohort hides foster entries', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_cohort_myPets')));
    await tester.pumpAndSettle();

    expect(find.text('Heartgard'), findsOneWidget);
    expect(find.text('Flea treatment'), findsNothing);
  });

  testWidgets('foster cohort hides owned entries', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global_events_cohort_fosterPets')));
    await tester.pumpAndSettle();

    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Heartgard'), findsNothing);
  });

  testWidgets('multi-select pet filters combine with OR', (tester) async {
    await tester.pumpWidget(buildEventsScreen());
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

    final notifier = TestMutableEntriesNotifier([_ownedEntry]);
    await tester.pumpWidget(
      buildListScreen(pets: const [_ownedPet], notifierFactory: () => notifier),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('global_events_mobile_row_entry-owned')),
      findsOneWidget,
    );

    notifier.publishTerminalError();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byKey(const Key('global_events_retry')), findsOneWidget);
    expect(
      find.byKey(const Key('global_events_mobile_row_entry-owned')),
      findsNothing,
    );
    expect(find.text('No entries yet'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Layout breakpoint tests
  // ---------------------------------------------------------------------------

  testWidgets('uses MobileDueEventRow at 390px phone width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildListScreen(
        pets: const [_ownedPet],
        notifierFactory: () => TestFixedEntriesNotifier([_ownedEntry]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global_events_mobile_list')), findsOneWidget);
    expect(find.byType(MobileDueEventRow), findsOneWidget);
  });

  testWidgets('uses desktop list at >=600px width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildListScreen(
        pets: const [_ownedPet],
        notifierFactory: () => TestFixedEntriesNotifier([_ownedEntry]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global_events_desktop_list')), findsOneWidget);
    expect(find.byType(MobileDueEventRow), findsNothing);
  });
}
