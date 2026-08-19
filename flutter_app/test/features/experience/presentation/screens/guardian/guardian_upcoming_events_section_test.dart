import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/dashboard_section.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_upcoming_events_section.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/due_event_card.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/mobile_due_event_row.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

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

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

Widget _buildSection({
  List<Pet> pets = const [],
  HealthEntriesNotifier Function()? notifierFactory,
}) {
  return ProviderScope(
    overrides: [
      healthEntriesNotifierProvider.overrideWith(
        notifierFactory ?? FakeHealthEntriesNotifier.new,
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: GuardianUpcomingEventsSection(pets: pets)),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('upcoming events section renders title', (tester) async {
    await tester.pumpWidget(_buildSection());
    await tester.pumpAndSettle();

    expect(find.text('Due and Overdue'), findsOneWidget);
    expect(find.byType(DashboardSection), findsOneWidget);
  });

  group('breakpoints', () {
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

      expect(find.byKey(const Key('mobile_due_event_list')), findsOneWidget);
      expect(
        find.byKey(const Key('mobile_due_row_due-entry-1')),
        findsOneWidget,
      );
      expect(find.byType(MobileDueEventRow), findsOneWidget);
    });

    testWidgets('does NOT use MobileDueEventRow at 600px desktop width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildSection(
          pets: const [_pet],
          notifierFactory: () => _FixedHealthEntriesNotifier([_dueEntry]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MobileDueEventRow), findsNothing);
      expect(find.byType(DueEventCard), findsOneWidget);
    });

    testWidgets('uses DueEventCard at a 900px desktop width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildSection(
          pets: const [_pet],
          notifierFactory: () => _FixedHealthEntriesNotifier([_dueEntry]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MobileDueEventRow), findsNothing);
      expect(find.byType(DueEventCard), findsOneWidget);
    });

    testWidgets('shows no-events text when due list is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildSection(pets: const [_pet]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile_due_event_list')), findsNothing);
      expect(find.text('No events are overdue or due today.'), findsOneWidget);
    });
  });

  group('list-level optimistic completion merge', () {
    testWidgets(
      'completed row remains visible after server excludes the entry',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildSection(
            pets: const [_pet],
            notifierFactory: () =>
                _ServerLikeHealthEntriesNotifier([_dueEntry]),
          ),
        );
        await tester.pumpAndSettle();

        // Initially the due row is shown with the mark-done check.
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);

        // Tap mark-done to open the completion sheet, then confirm.
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
        expect(find.text('Mark Completed'), findsOneWidget);
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // markTaken has removed the entry from the server list, but the
        // list-level optimistic state keeps the completed row visible in place.
        expect(
          find.byKey(const Key('mobile_due_row_due-entry-1')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Undo Complete'), findsOneWidget);
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
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.text('Undo Complete'), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.byKey(const Key('mobile_due_row_due-entry-1')),
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
        expect(find.byType(MobileDueEventRow), findsNWidgets(5));
        expect(find.byKey(const Key('mobile_due_row_e6')), findsNothing);

        // Complete the first row (Alpha) via its check button.
        final firstCheck = find.byIcon(Icons.check).first;
        await tester.tap(firstCheck);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();

        // Still exactly five rows. Alpha remains as completed at index 0; the
        // sixth entry (Foxtrot) is NOT added as an extra row.
        expect(find.byType(MobileDueEventRow), findsNWidgets(5));
        expect(find.byKey(const Key('mobile_due_row_e1')), findsOneWidget);
        expect(find.byKey(const Key('mobile_due_row_e6')), findsNothing);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        // The completed Alpha row is the first row in the list.
        final rows = tester.widgetList<MobileDueEventRow>(
          find.byType(MobileDueEventRow),
        );
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
          find.byKey(const Key('mobile_due_row_due-entry-1')),
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
          find.byKey(const Key('mobile_due_row_due-entry-1')),
          findsOneWidget,
          reason: 'completed row must stay visible during AsyncLoading',
        );
        expect(
          find.byIcon(Icons.check_circle),
          findsOneWidget,
          reason: 'completed icon must be present during AsyncLoading',
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Now let markTaken complete (server removes entry, AsyncData arrives).
        completer.complete();
        await tester.pumpAndSettle();

        // After AsyncData: the optimistic completed row is still present
        // because the list-level _completed state was not cleared.
        expect(
          find.byKey(const Key('mobile_due_row_due-entry-1')),
          findsOneWidget,
          reason: 'completed row must stay visible after AsyncData',
        );
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Undo Complete'), findsOneWidget);
      },
    );
  });
}
