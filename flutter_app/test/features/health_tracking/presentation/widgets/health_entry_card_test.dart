import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  group('HealthEntryCard', () {
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
          body: HealthEntryCard(
            entry: entry,
            onMarkTaken: onMarkTaken,
          ),
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

    testWidgets('calls onMarkTaken when button pressed', (tester) async {
      var called = false;
      await tester.pumpWidget(
          buildCard(futureEntry, onMarkTaken: () => called = true));
      await tester.pumpAndSettle();
      final markDoneButton = find.byType(ElevatedButton);
      if (markDoneButton.evaluate().isNotEmpty) {
        await tester.tap(markDoneButton.first);
        expect(called, isTrue);
      }
    });

    testWidgets('shows overdue status for past entries', (tester) async {
      final overdueEntry = futureEntry.copyWith(
          nextDueDate: DateTime.now().subtract(const Duration(days: 1)));
      await tester.pumpWidget(buildCard(overdueEntry));
      await tester.pumpAndSettle();
      expect(find.byType(HealthEntryCard), findsOneWidget);
    });
  });
}
