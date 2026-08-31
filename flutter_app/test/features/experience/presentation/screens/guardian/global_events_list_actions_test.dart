// Optimistic completion / undo and filter-after-completion tests for
// GlobalEventsList on both mobile (<600dp) and desktop (>=600dp) layouts.
import 'package:flutter/material.dart';

import 'guardian_events_test_helpers.dart';

// ---------------------------------------------------------------------------
// Shared entry fixture
// ---------------------------------------------------------------------------

final _entry = makeDueEntry(
  id: 'entry-due',
  petId: 'pet-owned',
  name: 'Morning walk',
);

const _pet = testOwnedPet;

// ---------------------------------------------------------------------------
// Mobile completion / undo
// ---------------------------------------------------------------------------

void main() {
  group('mobile (<600dp) optimistic completion/undo', () {
    setUp(() async {});

    testWidgets('completed row stays visible after server removes the entry', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildListScreen(
          pets: const [_pet],
          notifierFactory: () => TestServerLikeNotifier([_entry]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('global_events_row_entry-due')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.textContaining("Completed"), findsNothing);

      // Tap mark-done and confirm.
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(find.text('Mark Completed'), findsOneWidget);
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      // Server removed it, optimistic state keeps the row visible.
      expect(
        find.byKey(const Key('global_events_row_entry-due')),
        findsOneWidget,
      );
      expect(find.textContaining("Completed"), findsOneWidget);
      expect(find.text('Undo Complete'), findsOneWidget);
    });

    testWidgets('Undo calls undoComplete and restores the due row', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final notifier = TestServerLikeNotifier([_entry]);
      await tester.pumpWidget(
        buildListScreen(pets: const [_pet], notifierFactory: () => notifier),
      );
      await tester.pumpAndSettle();

      // Complete.
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();
      expect(find.text('Undo Complete'), findsOneWidget);

      // Undo.
      await tester.tap(find.text('Undo Complete'));
      await tester.pumpAndSettle();

      expect(notifier.undoCalls, 1);
      expect(notifier.lastUndoId, 'entry-due');
      expect(find.textContaining("Completed"), findsNothing);
      expect(find.text('Undo Complete'), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.byKey(const Key('global_events_row_entry-due')),
        findsOneWidget,
      );
    });

    testWidgets('failure rolls back optimistic row and shows feedback', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildListScreen(
          pets: const [_pet],
          notifierFactory: () => TestFailingMarkTakenNotifier([_entry]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      // Rolled back.
      expect(find.textContaining("Completed"), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
      // Error snackbar.
      expect(
        find.text('Could not mark this care item as done. Try again.'),
        findsOneWidget,
      );
      expect(find.text('Undo Complete'), findsNothing);
    });

    testWidgets('mobile undo failure keeps completed row and shows feedback', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildListScreen(
          pets: const [_pet],
          notifierFactory: () => TestFailingUndoNotifier([_entry]),
        ),
      );
      await tester.pumpAndSettle();

      // Complete the entry (markTaken succeeds).
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      // Completed state is shown.
      expect(find.textContaining("Completed"), findsOneWidget);
      expect(find.text('Undo Complete'), findsOneWidget);

      // Tap Undo — server rejects it.
      await tester.tap(find.text('Undo Complete'));
      await tester.pumpAndSettle();

      // Completed row must remain visible (not rolled back).
      expect(find.textContaining("Completed"), findsOneWidget);
      expect(find.text('Undo Complete'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      // Error snackbar.
      expect(
        find.text('Could not undo completion. Try again.'),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Desktop (>=600dp) completion / undo
  // ---------------------------------------------------------------------------

  group('desktop (>=600dp) optimistic completion/undo', () {
    testWidgets('mark-done button is visible on desktop and completes entry', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildListScreen(
          pets: const [_pet],
          notifierFactory: () => TestServerLikeNotifier([_entry]),
        ),
      );
      await tester.pumpAndSettle();

      // Desktop key present.
      expect(find.byKey(const Key('global_events_list')), findsOneWidget);
      expect(
        find.byKey(Key('care_event_row_done_${_entry.id}')),
        findsOneWidget,
      );

      // Tap mark-done.
      await tester.tap(find.byKey(Key('care_event_row_done_${_entry.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Mark Completed'), findsOneWidget);
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      // Completed state.
      expect(
        find.byKey(Key('care_event_row_undo_${_entry.id}')),
        findsOneWidget,
      );
      expect(find.byKey(Key('care_event_row_done_${_entry.id}')), findsNothing);
    });

    testWidgets('Undo on desktop restores the due row', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final notifier = TestServerLikeNotifier([_entry]);
      await tester.pumpWidget(
        buildListScreen(pets: const [_pet], notifierFactory: () => notifier),
      );
      await tester.pumpAndSettle();

      // Complete.
      await tester.tap(find.byKey(Key('care_event_row_done_${_entry.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      // Undo.
      await tester.tap(find.byKey(Key('care_event_row_undo_${_entry.id}')));
      await tester.pumpAndSettle();

      expect(notifier.undoCalls, 1);
      expect(notifier.lastUndoId, 'entry-due');
      // Due row restored.
      expect(
        find.byKey(Key('care_event_row_done_${_entry.id}')),
        findsOneWidget,
      );
      expect(find.byKey(Key('care_event_row_undo_${_entry.id}')), findsNothing);
    });

    testWidgets(
      'desktop failure rolls back optimistic row and shows feedback',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildListScreen(
            pets: const [_pet],
            notifierFactory: () => TestFailingMarkTakenNotifier([_entry]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(Key('care_event_row_done_${_entry.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // Rolled back.
        expect(
          find.byKey(Key('care_event_row_done_${_entry.id}')),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('care_event_row_undo_${_entry.id}')),
          findsNothing,
        );
        // Error snackbar.
        expect(
          find.text('Could not mark this care item as done. Try again.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('desktop undo failure keeps completed row and shows feedback', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildListScreen(
          pets: const [_pet],
          notifierFactory: () => TestFailingUndoNotifier([_entry]),
        ),
      );
      await tester.pumpAndSettle();

      // Complete the entry (markTaken succeeds).
      await tester.tap(find.byKey(Key('care_event_row_done_${_entry.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      // Completed state is shown.
      expect(
        find.byKey(Key('care_event_row_undo_${_entry.id}')),
        findsOneWidget,
      );

      // Tap Undo — server rejects it.
      await tester.tap(find.byKey(Key('care_event_row_undo_${_entry.id}')));
      await tester.pumpAndSettle();

      // Completed row must remain visible (not rolled back).
      expect(
        find.byKey(Key('care_event_row_undo_${_entry.id}')),
        findsOneWidget,
      );
      expect(find.byKey(Key('care_event_row_done_${_entry.id}')), findsNothing);
      // Error snackbar.
      expect(
        find.text('Could not undo completion. Try again.'),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Filter-after-completion: completed items must honor active filters
  // ---------------------------------------------------------------------------

  group('filter-after-completion: optimistic items respect active filters', () {
    // Owned-pet entry (type: other) — used across these tests.
    final _ownedEntry = makeDueEntry(
      id: 'filter-entry',
      petId: 'pet-owned',
      name: 'Daily Walk',
    );

    const _ownedPet = testOwnedPet; // pet-owned
    const _fosterPet = testFosterPet; // pet-foster

    testWidgets(
      'completed item is hidden when cohort filter excludes its pet (mobile)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildListScreen(
            pets: const [_ownedPet, _fosterPet],
            notifierFactory: () => TestServerLikeNotifier([_ownedEntry]),
          ),
        );
        await tester.pumpAndSettle();

        // Complete the owned-pet entry.
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // Optimistic row is visible while no filter is active.
        expect(
          find.byKey(const Key('global_events_row_filter-entry')),
          findsOneWidget,
        );

        // Switch cohort to "Foster pets" — owned-pet entry is excluded.
        final fosterFilter = find.byKey(
          const Key('global_events_cohort_fosterPets'),
        );
        await tester.ensureVisible(fosterFilter);
        await tester.tap(fosterFilter);
        await tester.pumpAndSettle();

        // Completed owned-pet row must not appear under the foster filter.
        expect(
          find.byKey(const Key('global_events_row_filter-entry')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'completed item is hidden when pet filter excludes its pet (desktop)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildListScreen(
            pets: const [_ownedPet, _fosterPet],
            notifierFactory: () => TestServerLikeNotifier([_ownedEntry]),
          ),
        );
        await tester.pumpAndSettle();

        // Complete via desktop mark-done button.
        await tester.tap(
          find.byKey(const Key('care_event_row_done_filter-entry')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // Undo button visible — optimistic row present.
        expect(
          find.byKey(const Key('care_event_row_undo_filter-entry')),
          findsOneWidget,
        );

        // Select only the foster pet via the individual pet chip.
        await tester.tap(find.byKey(const Key('global_events_pet_pet-foster')));
        await tester.pumpAndSettle();

        // Completed owned-pet row must not appear under the foster-pet filter.
        expect(
          find.byKey(const Key('care_event_row_undo_filter-entry')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'completed item is hidden when event-type filter excludes its type (mobile)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Medication entry — will be excluded when we filter to "Preventive".
        final medicationEntry = HealthEntry(
          id: 'filter-med',
          petId: 'pet-owned',
          name: 'Tablet',
          type: HealthEntryType.medication,
          dosage: '',
          frequency: HealthFrequency.daily,
          startDate: DateTime(2025, 1, 1),
          nextDueDate: DateTime.now(),
        );

        await tester.pumpWidget(
          buildListScreen(
            pets: const [_ownedPet],
            notifierFactory: () => TestServerLikeNotifier([medicationEntry]),
          ),
        );
        await tester.pumpAndSettle();

        // Complete the medication entry.
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // Optimistic row present before filtering.
        expect(
          find.byKey(const Key('global_events_row_filter-med')),
          findsOneWidget,
        );

        // Switch type filter to "Preventive" — excludes medication.
        final preventiveFilter = find.byKey(
          const Key('manage_events_type_preventive'),
        );
        await tester.ensureVisible(preventiveFilter);
        await tester.tap(preventiveFilter);
        await tester.pumpAndSettle();

        // Completed medication row must not appear under the preventive filter.
        expect(
          find.byKey(const Key('global_events_row_filter-med')),
          findsNothing,
        );
      },
    );

    // -- Status filter tests -------------------------------------------------
    // Verify that the synthetic post-completion filterEntry is used so that
    // status filters see the correct completed state, not the original
    // pre-completion data.

    testWidgets(
      'one-time completed item is visible under Closed status filter (mobile)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final oneTimeEntry = HealthEntry(
          id: 'status-once',
          petId: 'pet-owned',
          name: 'One-time check',
          type: HealthEntryType.other,
          dosage: '',
          frequency: HealthFrequency.once,
          startDate: DateTime(2025, 1, 1),
          nextDueDate: DateTime.now(),
        );

        await tester.pumpWidget(
          buildListScreen(
            pets: const [_ownedPet],
            notifierFactory: () => TestServerLikeNotifier([oneTimeEntry]),
          ),
        );
        await tester.pumpAndSettle();

        // Complete the one-time entry.
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // Switch status filter to "Closed".
        await tester.tap(find.byKey(const Key('manage_events_status_closed')));
        await tester.pumpAndSettle();

        // One-time completed entry is closed — must remain visible.
        expect(
          find.byKey(const Key('global_events_row_status-once')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'recurring completed item stays visible under Open status filter (desktop)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final recurringEntry = HealthEntry(
          id: 'status-recur',
          petId: 'pet-owned',
          name: 'Daily vitamin',
          type: HealthEntryType.medication,
          dosage: '',
          frequency: HealthFrequency.daily,
          startDate: DateTime(2025, 1, 1),
          nextDueDate: DateTime.now(),
        );

        await tester.pumpWidget(
          buildListScreen(
            pets: const [_ownedPet],
            notifierFactory: () => TestServerLikeNotifier([recurringEntry]),
          ),
        );
        await tester.pumpAndSettle();

        // Complete the recurring entry.
        await tester.tap(
          find.byKey(const Key('care_event_row_done_status-recur')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // Switch status filter to "Open".
        await tester.tap(find.byKey(const Key('manage_events_status_open')));
        await tester.pumpAndSettle();

        // Recurring completed entry — series still open — must remain visible.
        expect(
          find.byKey(const Key('care_event_row_undo_status-recur')),
          findsOneWidget,
        );
      },
    );
  });
}
