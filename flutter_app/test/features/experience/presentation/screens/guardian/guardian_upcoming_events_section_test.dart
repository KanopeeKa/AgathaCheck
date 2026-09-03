import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_upcoming_events_section.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_operations_desk_layout.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_event_row.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';
import 'guardian_events_test_helpers.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _pet = Pet(id: 'pet-1', name: 'Miso', species: 'Dog');

HealthEntry _due(String id, String name) => HealthEntry(
  id: id,
  petId: _pet.id,
  name: name,
  type: HealthEntryType.other,
  frequency: HealthFrequency.daily,
  startDate: DateTime(2024, 1, 1),
  nextDueDate: DateTime.now(),
);

final _dueEntry = _due('due-entry-1', 'Midday water check');

HealthEntry _entryAt(
  String id,
  String name,
  DateTime dueDate, {
  int remindDaysBefore = 1,
}) => HealthEntry(
  id: id,
  petId: _pet.id,
  name: name,
  type: HealthEntryType.other,
  frequency: HealthFrequency.daily,
  startDate: DateTime(2024, 1, 1),
  nextDueDate: dueDate,
  remindDaysBefore: remindDaysBefore,
);

// ---------------------------------------------------------------------------
// Notifier helpers
// ---------------------------------------------------------------------------

/// Simple notifier returning a fixed list — for layout/breakpoint tests.
class _FixedHealthEntriesNotifier extends HealthEntriesNotifier {
  _FixedHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_entries);
}

/// Notifier that models the authoritative server: [markTaken] removes the entry
/// from the due list (as guardianDueEntries would after completion), and
/// [undoComplete] restores it. Used to prove the list-level optimistic merge.
class _ServerLikeHealthEntriesNotifier extends HealthEntriesNotifier {
  _ServerLikeHealthEntriesNotifier(this._initial);

  final List<HealthEntry> _initial;
  int undoCompleteCalls = 0;
  String? lastUndoId;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  @override
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    // Simulate the server refresh removing the completed entry from the list.
    final current = state.valueOrNull ?? _initial;
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
  }

  @override
  Future<void> undoComplete(String id) async {
    undoCompleteCalls++;
    lastUndoId = id;
    // Restore the entry (as the server refresh would after undo).
    final current = state.valueOrNull ?? const <HealthEntry>[];
    if (!current.any((e) => e.id == id)) {
      final restored = _initial.firstWhere((e) => e.id == id);
      state = AsyncValue.data([...current, restored]);
    }
  }
}

/// Notifier whose [markTaken] publishes [AsyncLoading] first, waits on a
/// [Completer], then publishes the server result (entry removed from list).
///
/// Used to test the AsyncLoading → AsyncData lifecycle: the mobile preview
/// must remain visible (with the optimistic completed row) during loading.
class _SlowMarkTakenNotifier extends HealthEntriesNotifier {
  _SlowMarkTakenNotifier(this._initial, this._completer);

  final List<HealthEntry> _initial;

  /// The test controls when markTaken resolves by completing this.
  final Completer<void> _completer;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  @override
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    // Emit AsyncLoading immediately (mirrors what refresh() does in production).
    state = const AsyncValue.loading();
    // Wait until the test unblocks the completer.
    await _completer.future;
    // Publish the server result: entry removed from due list.
    state = AsyncValue.data(_initial.where((e) => e.id != id).toList());
  }
}

class _FailingMarkTakenNotifier extends HealthEntriesNotifier {
  _FailingMarkTakenNotifier(this._initial);

  final List<HealthEntry> _initial;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  @override
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    throw StateError('server rejected completion');
  }
}

class _SlowUndoNotifier extends HealthEntriesNotifier {
  _SlowUndoNotifier(this._initial, this._undoCompleter);

  final List<HealthEntry> _initial;
  final Completer<void> _undoCompleter;
  int undoCompleteCalls = 0;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  @override
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    final current = state.valueOrNull ?? _initial;
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
  }

  @override
  Future<void> undoComplete(String id) async {
    undoCompleteCalls++;
    await _undoCompleter.future;
    final current = state.valueOrNull ?? const <HealthEntry>[];
    final restored = _initial.firstWhere((entry) => entry.id == id);
    state = AsyncValue.data([...current, restored]);
  }
}

class _MutableHealthEntriesNotifier extends HealthEntriesNotifier {
  _MutableHealthEntriesNotifier(this._initial);

  final List<HealthEntry> _initial;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  void publishTerminalError() {
    state = AsyncValue.error(StateError('unavailable'), StackTrace.current);
  }
}

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

Widget _buildSection({
  List<Pet> pets = const [],
  HealthEntriesNotifier Function()? notifierFactory,
  VoidCallback? onAddEvent,
}) {
  return ProviderScope(
    overrides: [
      healthEntriesNotifierProvider.overrideWith(
        notifierFactory ?? FakeHealthEntriesNotifier.new,
      ),
      ...guardianEventsTestOverrides,
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme.copyWith(
        splashFactory: NoSplash.splashFactory,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GuardianUpcomingEventsSection(pets: pets, onAddEvent: onAddEvent),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('Care preview renders one combined list without tabs', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSection());
    await tester.pumpAndSettle();

    expect(find.text('CARE ACTIONS'), findsOneWidget);
    expect(
      find.byKey(const Key('guardian_dashboard_care_block')),
      findsOneWidget,
    );
    expect(find.byType(GuardianDeskSectionCard), findsOneWidget);
    expect(find.textContaining('Due'), findsNothing);
    expect(find.text('Soon'), findsNothing);
  });

  testWidgets('retains the existing Add an event handoff', (tester) async {
    var addEventCalls = 0;

    await tester.pumpWidget(_buildSection(onAddEvent: () => addEventCalls++));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('guardian_dashboard_empty_care_action')),
    );
    await tester.pumpAndSettle();

    expect(addEventCalls, 1);
  });

  group('baseline: responsive care preview', () {
    testWidgets('uses compact completion rows at a 390px phone width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildSection(
          pets: const [_pet],
          notifierFactory: () => _FixedHealthEntriesNotifier([_dueEntry]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('care_event_row_list')), findsOneWidget);
      expect(
        find.byKey(const Key('care_event_row_due-entry-1')),
        findsOneWidget,
      );
      expect(find.byType(CareEventRow), findsOneWidget);
    });

    testWidgets('uses list rows at a 600px desktop width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildSection(
          pets: const [_pet],
          notifierFactory: () => _FixedHealthEntriesNotifier([_dueEntry]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CareEventRow), findsOneWidget);
    });

    testWidgets('uses list rows at a 900px desktop width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildSection(
          pets: const [_pet],
          notifierFactory: () => _FixedHealthEntriesNotifier([_dueEntry]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CareEventRow), findsOneWidget);
    });

    testWidgets('shows no-events text when due list is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildSection(pets: const [_pet]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('care_event_row_list')), findsNothing);
      expect(find.text('Start their care routine'), findsOneWidget);
      expect(
        find.byKey(const Key('guardian_dashboard_empty_care')),
        findsOneWidget,
      );
    });

    testWidgets('shows five combined care rows in due-date order', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final today = DateTime.now();
      final entries = [
        _entryAt(
          'upcoming-later',
          'Upcoming later',
          today.add(const Duration(days: 2)),
          remindDaysBefore: 3,
        ),
        _entryAt('due-today', 'Due today', today),
        _entryAt(
          'overdue-recent',
          'Overdue recent',
          today.subtract(const Duration(days: 1)),
        ),
        _entryAt(
          'upcoming-soon',
          'Upcoming soon',
          today.add(const Duration(days: 1)),
          remindDaysBefore: 3,
        ),
        _entryAt(
          'overdue-oldest',
          'Overdue oldest',
          today.subtract(const Duration(days: 4)),
        ),
        _entryAt(
          'outside-window',
          'Outside window',
          today.add(const Duration(days: 7)),
        ),
      ];

      await tester.pumpWidget(
        _buildSection(
          pets: const [_pet],
          notifierFactory: () => _FixedHealthEntriesNotifier(entries),
        ),
      );
      await tester.pumpAndSettle();

      final rows = tester.widgetList<CareEventRow>(find.byType(CareEventRow));
      expect(rows, hasLength(5));
      expect(rows.map((row) => row.entry.id), [
        'overdue-oldest',
        'overdue-recent',
        'due-today',
        'upcoming-soon',
        'upcoming-later',
      ]);
    });
  });

  testWidgets('error state is retryable and not shown as the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSection(
        pets: const [_pet],
        notifierFactory: _ErrorHealthEntriesNotifier.new,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('We couldn\'t load care right now.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Nothing needs care today.'), findsNothing);
  });

  testWidgets(
    'terminal error replaces a cached preview rather than showing it as empty or fresh data',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final notifier = _MutableHealthEntriesNotifier([_dueEntry]);

      await tester.pumpWidget(
        _buildSection(pets: const [_pet], notifierFactory: () => notifier),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('care_event_row_due-entry-1')),
        findsOneWidget,
      );

      notifier.publishTerminalError();
      await tester.pumpAndSettle();

      expect(find.text('We couldn\'t load care right now.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byKey(const Key('care_event_row_due-entry-1')), findsNothing);
      expect(find.text('Nothing needs care today.'), findsNothing);
    },
  );

  group('baseline: list-level optimistic completion merge', () {
    testWidgets(
      'completed row remains visible after server excludes the entry',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final soonEntry = _entryAt(
          'soon-entry-1',
          'Soon care',
          DateTime.now().add(const Duration(days: 1)),
          remindDaysBefore: 1,
        );
        await tester.pumpWidget(
          _buildSection(
            pets: const [_pet],
            notifierFactory: () =>
                _ServerLikeHealthEntriesNotifier([_dueEntry, soonEntry]),
          ),
        );
        await tester.pumpAndSettle();

        // The combined list exposes one completion action per open item.
        expect(find.byIcon(Icons.check), findsNWidgets(2));
        expect(find.textContaining("Completed"), findsNothing);

        // Tap mark-done to open the completion sheet, then confirm.
        await tester.tap(find.byIcon(Icons.check).first);
        await tester.pumpAndSettle();
        expect(find.text('Mark Completed'), findsOneWidget);
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // markTaken has removed the entry from the server list, but the
        // list-level optimistic state keeps the completed row visible in place.
        expect(
          find.byKey(const Key('care_event_row_due-entry-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('care_event_row_undo_due-entry-1')),
          findsOneWidget,
        );
        expect(find.text('Undo Complete'), findsOneWidget);

        expect(
          find.byKey(const Key('care_event_row_soon-entry-1')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Undo calls undoComplete and restores the normal due row', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final notifier = _ServerLikeHealthEntriesNotifier([_dueEntry]);

      await tester.pumpWidget(
        _buildSection(pets: const [_pet], notifierFactory: () => notifier),
      );
      await tester.pumpAndSettle();

      // Complete it.
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Undo Complete'), findsOneWidget);

      // Undo.
      await tester.tap(find.text('Undo Complete'));
      await tester.pumpAndSettle();

      expect(notifier.undoCompleteCalls, 1);
      expect(notifier.lastUndoId, 'due-entry-1');

      // The normal due row is restored (mark-done check present again).
      expect(find.textContaining("Completed"), findsNothing);
      expect(find.text('Undo Complete'), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.byKey(const Key('care_event_row_due-entry-1')),
        findsOneWidget,
      );
    });

    testWidgets(
      'completed item stays at its original preview index as others shift',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Six due entries; preview caps at five. Completing the first should
        // keep it at index 0, not push a sixth row in.
        final entries = [
          _due('e1', 'Alpha'),
          _due('e2', 'Bravo'),
          _due('e3', 'Charlie'),
          _due('e4', 'Delta'),
          _due('e5', 'Echo'),
          _due('e6', 'Foxtrot'),
        ];

        await tester.pumpWidget(
          _buildSection(
            pets: const [_pet],
            notifierFactory: () => _ServerLikeHealthEntriesNotifier(entries),
          ),
        );
        await tester.pumpAndSettle();

        // Preview shows exactly five rows (e1..e5).
        expect(find.byType(CareEventRow), findsNWidgets(5));
        expect(find.byKey(const Key('care_event_row_e6')), findsNothing);

        // Complete the first row (Alpha) via its check button.
        final firstCheck = find.byIcon(Icons.check).first;
        await tester.tap(firstCheck);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // Still exactly five rows. Alpha remains as completed at index 0; the
        // sixth entry (Foxtrot) is NOT added as an extra row.
        expect(find.byType(CareEventRow), findsNWidgets(5));
        expect(find.byKey(const Key('care_event_row_e1')), findsOneWidget);
        expect(find.byKey(const Key('care_event_row_e6')), findsNothing);
        expect(find.byKey(const Key('care_event_row_undo_e1')), findsOneWidget);

        // The completed Alpha row is the first row in the list.
        final rows = tester.widgetList<CareEventRow>(find.byType(CareEventRow));
        expect(rows.first.entry.id, 'e1');
        expect(rows.first.isCompleted, isTrue);
      },
    );

    testWidgets(
      'AsyncLoading → AsyncData: completed row remains visible during loading '
      'and after data arrives',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Completer the test uses to pause markTaken in the AsyncLoading phase.
        final completer = Completer<void>();

        await tester.pumpWidget(
          _buildSection(
            pets: const [_pet],
            notifierFactory: () =>
                _SlowMarkTakenNotifier([_dueEntry], completer),
          ),
        );
        await tester.pumpAndSettle();

        // Initially the due row is shown.
        expect(
          find.byKey(const Key('care_event_row_due-entry-1')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check), findsOneWidget);

        // Tap mark-done and confirm in the completion sheet.
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
        expect(find.text('Mark Completed'), findsOneWidget);
        await tester.tap(find.text('Mark Completed'));

        // Pump one frame so the optimistic setState runs and markTaken begins
        // (but the completer has not fired yet → provider is in AsyncLoading).
        await tester.pump();

        // During AsyncLoading the mobile list must render from the snapshot —
        // the completed row must be visible, not replaced by a spinner.
        expect(
          find.byKey(const Key('care_event_row_due-entry-1')),
          findsOneWidget,
          reason: 'completed row must stay visible during AsyncLoading',
        );
        expect(
          find.byKey(const Key('care_event_row_undo_due-entry-1')),
          findsOneWidget,
          reason: 'undo affordance must be present during AsyncLoading',
        );
        expect(
          find.byKey(const Key('guardian_due_events_refreshing')),
          findsOneWidget,
          reason:
              'cached refresh must remain visibly distinct from settled data',
        );

        // Now let markTaken complete (server removes entry, AsyncData arrives).
        completer.complete();
        await tester.pumpAndSettle();

        // After AsyncData: the optimistic completed row is still present
        // because the list-level _completed state was not cleared.
        expect(
          find.byKey(const Key('care_event_row_due-entry-1')),
          findsOneWidget,
          reason: 'completed row must stay visible after AsyncData',
        );
        expect(
          find.byKey(const Key('care_event_row_undo_due-entry-1')),
          findsOneWidget,
        );
        expect(find.text('Undo Complete'), findsOneWidget);
      },
    );

    testWidgets(
      'completion failure rolls back the optimistic row and reports feedback',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildSection(
            pets: const [_pet],
            notifierFactory: () => _FailingMarkTakenNotifier([_dueEntry]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        expect(find.textContaining("Completed"), findsNothing);
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(
          find.text('Could not mark this care item as done. Try again.'),
          findsOneWidget,
        );
        expect(find.text('Undo Complete'), findsNothing);
      },
    );

    testWidgets('Undo stays visible until the authoritative undo succeeds', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final undoCompleter = Completer<void>();
      final notifier = _SlowUndoNotifier([_dueEntry], undoCompleter);

      await tester.pumpWidget(
        _buildSection(pets: const [_pet], notifierFactory: () => notifier),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();
      expect(find.text('Undo Complete'), findsOneWidget);

      await tester.tap(find.text('Undo Complete'));
      await tester.pump();

      expect(notifier.undoCompleteCalls, 1);
      expect(find.text('Undo Complete'), findsOneWidget);
      expect(find.textContaining("Completed"), findsOneWidget);

      undoCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.text('Undo Complete'), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}

class _ErrorHealthEntriesNotifier extends HealthEntriesNotifier {
  @override
  Future<List<HealthEntry>> build() async => throw StateError('unavailable');
}
