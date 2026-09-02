import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/occurrence_scheduling.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_event_row.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_event_row_context.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

final _overdueEntry = HealthEntry(
  id: 'entry-1',
  petId: 'pet-1',
  name: 'Parasite prevention',
  type: HealthEntryType.preventive,
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2024, 1, 1),
  nextDueDate: DateTime(2020, 1, 1),
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

Widget _buildRow(
  HealthEntry entry, {
  Pet? petArg,
  bool includeDefaultPet = true,
  CareEventRowContext rowContext = CareEventRowContext.dashboard,
  bool isCompleted = false,
  VoidCallback? onMarkDone,
  VoidCallback? onUndo,
  VoidCallback? onView,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme.copyWith(splashFactory: NoSplash.splashFactory),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CareEventRow(
        entry: entry,
        pet: includeDefaultPet ? petArg ?? _pet : null,
        rowContext: rowContext,
        isCompleted: isCompleted,
        onMarkDone: onMarkDone ?? () {},
        onUndo: onUndo ?? () {},
        onView: onView ?? () {},
      ),
    ),
  );
}

void main() {
  group('CareEventRow — due state', () {
    testWidgets('renders title and dashboard metadata lines', (tester) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      expect(find.text('Parasite prevention'), findsOneWidget);
      expect(find.text('Miso · Preventive'), findsOneWidget);
      expect(find.textContaining('Overdue'), findsOneWidget);
    });

    testWidgets('pet context omits pet name from metadata', (tester) async {
      await tester.pumpWidget(
        _buildRow(_overdueEntry, rowContext: CareEventRowContext.pet),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preventive'), findsOneWidget);
      expect(find.textContaining('Miso ·'), findsNothing);
    });

    testWidgets('does not show snooze or open actions', (tester) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      expect(find.text('Snooze'), findsNothing);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('mark-done button has >= 48dp touch target', (tester) async {
      await tester.pumpWidget(_buildRow(_overdueEntry));
      await tester.pumpAndSettle();

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final has48 = sizedBoxes.any(
        (sb) =>
            sb.width != null &&
            sb.width! >= 48 &&
            sb.height != null &&
            sb.height! >= 48,
      );
      expect(has48, isTrue);
    });

    testWidgets('tapping mark-done invokes callback', (tester) async {
      var marked = false;
      await tester.pumpWidget(
        _buildRow(_overdueEntry, onMarkDone: () => marked = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(marked, isTrue);
    });

    testWidgets('tapping row body invokes onView callback', (tester) async {
      var viewed = false;
      await tester.pumpWidget(
        _buildRow(_overdueEntry, onView: () => viewed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Parasite prevention'));
      await tester.pumpAndSettle();
      expect(viewed, isTrue);
    });
  });

  group('CareEventRow — completed state', () {
    testWidgets('shows completed presentation with undo', (tester) async {
      await tester.pumpWidget(_buildRow(_overdueEntry, isCompleted: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('Completed'), findsOneWidget);
      expect(find.text('Undo Complete'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });

  group('CareEventRow — semantics', () {
    testWidgets('view control opens via row content tap', (tester) async {
      var viewed = false;
      await tester.pumpWidget(
        _buildRow(_overdueEntry, onView: () => viewed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Parasite prevention'));
      await tester.pumpAndSettle();
      expect(viewed, isTrue);
    });

    testWidgets('view semantics onTap opens event view', (tester) async {
      var viewed = false;
      await tester.pumpWidget(
        _buildRow(_overdueEntry, onView: () => viewed = true),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('View Parasite prevention for Miso'),
      );
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        semantics.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(viewed, isTrue);
    });
  });

  group('CareEventRow — occurrence summary', () {
    testWidgets('shows occurrence-aware overdue status line', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final summary = OccurrenceSummary(
        openCount: 2,
        missedCount: 1,
        missedHead: HealthOccurrence(
          id: 'occ-1',
          entryId: 'entry-1',
          scheduledDate: yesterday,
          scheduledTime: '08:00',
          status: 'pending',
          missed: true,
        ),
        nextHead: HealthOccurrence(
          id: 'occ-2',
          entryId: 'entry-1',
          scheduledDate: DateTime.now(),
          scheduledTime: '20:00',
          status: 'pending',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme.copyWith(
            splashFactory: NoSplash.splashFactory,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareEventRow(
              entry: _overdueEntry,
              pet: _pet,
              rowContext: CareEventRowContext.dashboard,
              isCompleted: false,
              occurrenceSummary: summary,
              onMarkDone: () {},
              onUndo: () {},
              onView: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Overdue'), findsOneWidget);
      expect(find.textContaining('2 open'), findsOneWidget);
    });
  });
}
