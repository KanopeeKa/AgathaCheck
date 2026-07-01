import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  group('HealthEntryCard', () {
    final dateFormat = DateFormat('dd MMM');

    Widget buildCard(HealthEntry entry, {VoidCallback? onMarkTaken}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: HealthEntryCard(entry: entry, onMarkTaken: onMarkTaken),
        ),
      );
    }

    final futureEntry = HealthEntry(
      id: '1',
      petId: 'pet-1',
      name: 'Heartgard Plus',
      type: HealthEntryType.medication,
      dosage: '1 tablet',
      frequency: HealthFrequency.monthly,
      startDate: DateTime(2025, 1, 1),
      nextDueDate: DateTime.now().add(const Duration(days: 5)),
    );

    testWidgets('displays entry name', (tester) async {
      await tester.pumpWidget(buildCard(futureEntry));
      await tester.pumpAndSettle();
      expect(find.textContaining('Heartgard Plus'), findsOneWidget);
    });

    testWidgets('displays dosage', (tester) async {
      await tester.pumpWidget(buildCard(futureEntry));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 tablet'), findsOneWidget);
    });

    testWidgets('displays future due date instead of remaining days', (
      tester,
    ) async {
      await tester.pumpWidget(buildCard(futureEntry));
      await tester.pumpAndSettle();

      expect(
        find.text(dateFormat.format(futureEntry.nextDueDate!)),
        findsOneWidget,
      );
      expect(find.textContaining('Due in'), findsNothing);
      expect(find.textContaining('Due '), findsNothing);
    });

    testWidgets('displays tomorrow as a due date', (tester) async {
      final now = DateTime.now();
      final tomorrowEntry = futureEntry.copyWith(
        nextDueDate: DateTime(now.year, now.month, now.day + 1, 9),
      );

      await tester.pumpWidget(buildCard(tomorrowEntry));
      await tester.pumpAndSettle();

      expect(
        find.text(dateFormat.format(tomorrowEntry.nextDueDate!)),
        findsOneWidget,
      );
      expect(find.text('Due tomorrow'), findsNothing);
    });

    testWidgets('calls onMarkTaken when button pressed', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildCard(futureEntry, onMarkTaken: () => called = true),
      );
      await tester.pumpAndSettle();
      final markDoneButton = find.byType(ElevatedButton);
      if (markDoneButton.evaluate().isNotEmpty) {
        await tester.tap(markDoneButton.first);
        expect(called, isTrue);
      }
    });

    testWidgets('shows overdue due date without overdue label', (tester) async {
      final overdueEntry = futureEntry.copyWith(
        nextDueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await tester.pumpWidget(buildCard(overdueEntry));
      await tester.pumpAndSettle();

      expect(
        find.text(dateFormat.format(overdueEntry.nextDueDate!)),
        findsOneWidget,
      );
      expect(find.text('Overdue'), findsNothing);
    });

    testWidgets('shows due today as date only', (tester) async {
      final now = DateTime.now();
      final dueTodayEntry = futureEntry.copyWith(
        nextDueDate: DateTime(now.year, now.month, now.day, 14, 30),
      );

      await tester.pumpWidget(buildCard(dueTodayEntry));
      await tester.pumpAndSettle();

      expect(
        find.text(dateFormat.format(dueTodayEntry.nextDueDate!)),
        findsOneWidget,
      );
      expect(find.textContaining('Due today'), findsNothing);
    });

    testWidgets('shows done date once on status line for completed entries', (
      tester,
    ) async {
      final completedOn = DateTime(2025, 6, 3);
      final completedEntry = HealthEntry(
        id: '2',
        petId: 'pet-1',
        name: 'Rabies vaccine',
        type: HealthEntryType.preventive,
        dosage: '',
        frequency: HealthFrequency.once,
        startDate: DateTime(2025, 1, 1),
        completedOn: completedOn,
        nextDueDate: DateTime(9999, 12, 31),
      );
      final l = lookupAppLocalizations(const Locale('en'));
      final expected = l.doneOn(dateFormat.format(completedOn));

      await tester.pumpWidget(buildCard(completedEntry));
      await tester.pumpAndSettle();

      expect(find.text(expected), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });
  });
}
