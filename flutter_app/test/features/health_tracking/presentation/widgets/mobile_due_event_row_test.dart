import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/mobile_due_event_row.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

final _overdueEntry = HealthEntry(
  id: 'entry-1',
  petId: 'pet-1',
  name: 'Parasite prevention',
  type: HealthEntryType.preventive,
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2024, 1, 1),
  nextDueDate: DateTime(2020, 1, 1), // clearly overdue
);

final _dueEntry = HealthEntry(
  id: 'entry-2',
  petId: 'pet-1',
  name: 'Midday water check',
  type: HealthEntryType.other,
  frequency: HealthFrequency.daily,
  startDate: DateTime(2024, 1, 1),
  nextDueDate: DateTime.now(),
);

const _pet = Pet(id: 'pet-1', name: 'Miso', species: 'Dog');

// ---------------------------------------------------------------------------
// Widget builder — exercises the real MobileDueEventRow with real callbacks
// ---------------------------------------------------------------------------

Widget _buildRow(
  HealthEntry entry, {
  Pet? petArg,
  bool includeDefaultPet = true,
  bool isCompleted = false,
  VoidCallback? onMarkDone,
  VoidCallback? onUndo,
  VoidCallback? onOpen,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MobileDueEventRow(
        entry: entry,
        pet: includeDefaultPet ? petArg ?? _pet : null,
        isCompleted: isCompleted,
        onMarkDone: onMarkDone ?? () {},
        onUndo: onUndo ?? () {},
        onOpen: onOpen ?? () {},
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MobileDueEventRow — due state', () {
    testWidgets('renders entry name and pet name', (tester) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      expect(find.text('Parasite prevention'), findsOneWidget);
      expect(find.textContaining('Miso'), findsOneWidget);
    });

    testWidgets('shows overdue status icon for overdue entry', (tester) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows calendar icon for due-today entry', (tester) async {
      await tester.pumpWidget(_buildRow(_dueEntry));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('mark-done button has >= 48dp touch target', (tester) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      final checkFinder = find.byIcon(Icons.check);
      expect(checkFinder, findsOneWidget);

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final has48 = sizedBoxes.any(
        (sb) =>
            sb.width != null &&
            sb.width! >= 48 &&
            sb.height != null &&
            sb.height! >= 48,
      );
      expect(has48, isTrue, reason: 'Expected a >=48dp touch target SizedBox');
    });

    testWidgets('does NOT use MergeSemantics (accessibility fix)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      expect(find.byType(MergeSemantics), findsNothing);
    });

    testWidgets('urgency text shows "Overdue" for overdue entry', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      expect(find.textContaining('Overdue'), findsOneWidget);
    });

    testWidgets('urgency text shows "Due today" for today entry', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRow(_dueEntry));
      await tester.pumpAndSettle();

      expect(find.textContaining('Due today'), findsOneWidget);
    });

    testWidgets('mark-done Tooltip is present', (tester) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping mark-done invokes onMarkDone callback', (
      tester,
    ) async {
      var marked = false;
      await tester.pumpWidget(
        _buildRow(_overdueEntry, onMarkDone: () => marked = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(marked, isTrue);
    });

    testWidgets('tapping row body invokes onOpen callback', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        _buildRow(_overdueEntry, onOpen: () => opened = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Parasite prevention'));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('works without a pet entity (uses petName fallback)', (
      tester,
    ) async {
      final entryWithPetName = HealthEntry(
        id: 'entry-3',
        petId: 'pet-99',
        name: 'Evening walk',
        petName: 'Basil',
        type: HealthEntryType.other,
        frequency: HealthFrequency.daily,
        startDate: DateTime(2024, 1, 1),
        nextDueDate: DateTime.now(),
      );

      await tester.pumpWidget(
        _buildRow(entryWithPetName, includeDefaultPet: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evening walk'), findsOneWidget);
      expect(find.textContaining('Basil'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Compact phone width (390px)
  // -------------------------------------------------------------------------

  group('MobileDueEventRow — 390px compact width', () {
    testWidgets('renders correctly at 390px phone width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      expect(find.text('Parasite prevention'), findsOneWidget);
      expect(find.textContaining('Miso'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Completed presentation (driven by isCompleted)
  // -------------------------------------------------------------------------

  group('MobileDueEventRow — completed state', () {
    testWidgets('shows completed presentation when isCompleted is true', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRow(_overdueEntry, isCompleted: true));
      await tester.pumpAndSettle();

      // Filled completed chip
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // Completed subtitle text
      expect(find.textContaining('Completed'), findsOneWidget);
      // Undo affordance
      expect(find.text('Undo Complete'), findsOneWidget);
      // No mark-done check in completed state
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('tapping Undo invokes onUndo callback', (tester) async {
      var undone = false;
      await tester.pumpWidget(
        _buildRow(
          _overdueEntry,
          isCompleted: true,
          onUndo: () => undone = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo Complete'));
      await tester.pumpAndSettle();

      expect(undone, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // French localizations
  // -------------------------------------------------------------------------

  group('MobileDueEventRow — French locale', () {
    testWidgets('urgency text shows "En retard" for overdue in French', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRow(_overdueEntry, locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('En retard'), findsOneWidget);
    });

    testWidgets('urgency text shows "Aujourd\'hui" for due today in French', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRow(_dueEntry, locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(find.textContaining("Aujourd'hui"), findsOneWidget);
    });

    testWidgets('completed Undo label is localized in French', (tester) async {
      await tester.pumpWidget(
        _buildRow(_overdueEntry, isCompleted: true, locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();

      // French undo text (from undoComplete ARB key with \n replaced by space)
      expect(find.textContaining('Annuler'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Semantics: each labelled control exposes SemanticsAction.tap
  // -------------------------------------------------------------------------

  group('MobileDueEventRow — semantics actions', () {
    testWidgets(
      'Open control exposes SemanticsAction.tap for assistive technology',
      (tester) async {
        final handle = tester.ensureSemantics();

        var openCalled = false;
        await tester.pumpWidget(
          _buildRow(_overdueEntry, onOpen: () => openCalled = true),
        );
        await tester.pumpAndSettle();

        // Verify the outer Semantics node for Open exposes SemanticsAction.tap.
        final openNode = tester.getSemantics(
          find.bySemanticsLabel(RegExp(r'Open Parasite prevention for Miso')),
        );
        expect(
          openNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'Open Semantics node must expose SemanticsAction.tap',
        );

        // Verify the action actually invokes the callback via the semantics layer.
        tester.semantics.tap(
          find.semantics.byLabel(RegExp(r'Open Parasite prevention for Miso')),
        );
        await tester.pumpAndSettle();
        expect(openCalled, isTrue);

        handle.dispose();
      },
    );

    testWidgets(
      'Mark done control exposes SemanticsAction.tap for assistive technology',
      (tester) async {
        final handle = tester.ensureSemantics();

        var markDoneCalled = false;
        await tester.pumpWidget(
          _buildRow(_overdueEntry, onMarkDone: () => markDoneCalled = true),
        );
        await tester.pumpAndSettle();

        final markDoneNode = tester.getSemantics(
          find.bySemanticsLabel(RegExp(r'Mark Parasite prevention as done')),
        );
        expect(
          markDoneNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'Mark done Semantics node must expose SemanticsAction.tap',
        );

        tester.semantics.tap(
          find.semantics.byLabel(RegExp(r'Mark Parasite prevention as done')),
        );
        await tester.pumpAndSettle();
        expect(markDoneCalled, isTrue);

        handle.dispose();
      },
    );

    testWidgets(
      'Undo control exposes SemanticsAction.tap for assistive technology',
      (tester) async {
        final handle = tester.ensureSemantics();

        var undoCalled = false;
        await tester.pumpWidget(
          _buildRow(
            _overdueEntry,
            isCompleted: true,
            onUndo: () => undoCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        final undoNode = tester.getSemantics(
          find.bySemanticsLabel(
            RegExp(r'Undo completion of Parasite prevention'),
          ),
        );
        expect(
          undoNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'Undo Semantics node must expose SemanticsAction.tap',
        );

        tester.semantics.tap(
          find.semantics.byLabel(
            RegExp(r'Undo completion of Parasite prevention'),
          ),
        );
        await tester.pumpAndSettle();
        expect(undoCalled, isTrue);

        handle.dispose();
      },
    );
  });
}
