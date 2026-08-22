// Focused semantics-tree and action tests for DesktopCareRow.
//
// Verifies that:
//  - Open, Mark-Done, and Undo each carry an independent localized semantic
//    label and expose SemanticsAction.tap, so assistive technology can target
//    them individually.
//  - MergeSemantics is absent: Open and Mark-Done are separately labelled
//    button nodes (not collapsed into one).
//  - Each action callback fires when the semantic tap action is triggered.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/desktop_care_row.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _dueEntry = HealthEntry(
  id: 'sem-entry',
  petId: 'sem-pet',
  name: 'Morning Tablet',
  type: HealthEntryType.medication,
  dosage: '',
  frequency: HealthFrequency.daily,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime.now(),
);

const _pet = Pet(id: 'sem-pet', name: 'Buddy', species: 'Dog', breed: '');

// ---------------------------------------------------------------------------
// Localized label constants (en-US, matches app_localizations_en.dart)
// ---------------------------------------------------------------------------

// dueEventRowOpenLabel('Morning Tablet', 'Buddy') → 'Open Morning Tablet for Buddy'
const _openLabel = 'Open Morning Tablet for Buddy';

// dueEventRowMarkDoneLabel('Morning Tablet') → 'Mark Morning Tablet as done'
const _markDoneLabel = 'Mark Morning Tablet as done';

// dueEventRowUndoLabel('Morning Tablet') → 'Undo completion of Morning Tablet'
const _undoLabel = 'Undo completion of Morning Tablet';

// ---------------------------------------------------------------------------
// Builder
// ---------------------------------------------------------------------------

Widget _buildRow({
  required HealthEntry entry,
  bool isCompleted = false,
  VoidCallback? onMarkDone,
  VoidCallback? onUndo,
  VoidCallback? onOpen,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 800,
        child: DesktopCareRow(
          entry: entry,
          pet: _pet,
          isCompleted: isCompleted,
          onMarkDone: onMarkDone ?? () {},
          onUndo: onUndo ?? () {},
          onOpen: onOpen ?? () {},
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Due-row tests
// ---------------------------------------------------------------------------

void main() {
  group('DesktopCareRow due row — independent semantic actions', () {
    testWidgets(
      'Open action carries localized label and exposes SemanticsAction.tap',
      (tester) async {
        final handle = tester.ensureSemantics();

        var openCalled = false;
        await tester.pumpWidget(
          _buildRow(entry: _dueEntry, onOpen: () => openCalled = true),
        );
        await tester.pumpAndSettle();

        final openNode = tester.getSemantics(
          find.bySemanticsLabel(_openLabel).first,
        );
        expect(
          openNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'Open node must expose SemanticsAction.tap',
        );

        tester.semantics.tap(find.semantics.byLabel(_openLabel).first);
        await tester.pumpAndSettle();
        expect(openCalled, isTrue);
        handle.dispose();
      },
    );

    testWidgets(
      'Mark-Done action carries localized label and exposes SemanticsAction.tap',
      (tester) async {
        final handle = tester.ensureSemantics();

        var markDoneCalled = false;
        await tester.pumpWidget(
          _buildRow(entry: _dueEntry, onMarkDone: () => markDoneCalled = true),
        );
        await tester.pumpAndSettle();

        final markDoneNode = tester.getSemantics(
          find.bySemanticsLabel(_markDoneLabel).first,
        );
        expect(
          markDoneNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'Mark-Done node must expose SemanticsAction.tap',
        );

        tester.semantics.tap(find.semantics.byLabel(_markDoneLabel).first);
        await tester.pumpAndSettle();
        expect(markDoneCalled, isTrue);
        handle.dispose();
      },
    );

    testWidgets(
      'Open and Mark-Done are separate semantic nodes (MergeSemantics absent)',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(_buildRow(entry: _dueEntry));
        await tester.pumpAndSettle();

        final semanticsOwner =
            tester.binding.renderViews.first.owner!.semanticsOwner!;

        // Collect all tap-action node labels.
        final tapLabels = <String>{};
        void walk(SemanticsNode node) {
          final data = node.getSemanticsData();
          if (data.hasAction(SemanticsAction.tap) && node.label.isNotEmpty) {
            tapLabels.add(node.label);
          }
          node.visitChildren((child) {
            walk(child);
            return true;
          });
        }

        walk(semanticsOwner.rootSemanticsNode!);

        // Without MergeSemantics, Open and Mark-Done are distinct nodes.
        expect(
          tapLabels.contains(_openLabel),
          isTrue,
          reason: 'Open label must be an independent tap-action node',
        );
        expect(
          tapLabels.contains(_markDoneLabel),
          isTrue,
          reason: 'Mark-Done label must be an independent tap-action node',
        );
        handle.dispose();
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Completed-row tests
  // ---------------------------------------------------------------------------

  group('DesktopCareRow completed row — Undo semantic action', () {
    testWidgets(
      'Undo action carries localized label and exposes SemanticsAction.tap',
      (tester) async {
        final handle = tester.ensureSemantics();

        var undoCalled = false;
        await tester.pumpWidget(
          _buildRow(
            entry: _dueEntry,
            isCompleted: true,
            onUndo: () => undoCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        final undoNode = tester.getSemantics(
          find.bySemanticsLabel(_undoLabel).first,
        );
        expect(
          undoNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'Undo node must expose SemanticsAction.tap',
        );

        tester.semantics.tap(find.semantics.byLabel(_undoLabel).first);
        await tester.pumpAndSettle();
        expect(undoCalled, isTrue);
        handle.dispose();
      },
    );

    testWidgets('container semantic label includes pet name in completed row', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_buildRow(entry: _dueEntry, isCompleted: true));
      await tester.pumpAndSettle();

      // completedEventSemanticLabel('Morning Tablet', 'Buddy')
      // → 'Morning Tablet, completed, for Buddy'
      const expectedLabel = 'Morning Tablet, completed, for Buddy';

      final semanticsOwner =
          tester.binding.renderViews.first.owner!.semanticsOwner!;

      bool foundLabel = false;
      void walk(SemanticsNode node) {
        if (node.label == expectedLabel) foundLabel = true;
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      walk(semanticsOwner.rootSemanticsNode!);

      expect(
        foundLabel,
        isTrue,
        reason:
            'Completed row container must carry semantic label with pet name: "$expectedLabel"',
      );
      handle.dispose();
    });

    testWidgets('completed row renders pet strip (pet identity visible)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRow(entry: _dueEntry, isCompleted: true));
      await tester.pumpAndSettle();

      // HealthEntryPetStrip is present — the pet name text 'Buddy' or the
      // first letter 'B' is shown inside the strip.  We verify by checking
      // the pet-name text widget that the strip renders.
      expect(
        find.text('Buddy'),
        findsAtLeastNWidgets(1),
        reason: 'Completed row must show pet name via pet strip',
      );
    });
  });
}
