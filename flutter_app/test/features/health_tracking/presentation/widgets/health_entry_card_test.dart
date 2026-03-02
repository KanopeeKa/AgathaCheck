import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_card.dart';

void main() {
  group('HealthEntryCard', () {
    Widget buildCard(HealthEntry entry, {VoidCallback? onMarkTaken, VoidCallback? onDelete}) {
      return MaterialApp(
        home: Scaffold(
          body: HealthEntryCard(
            entry: entry,
            onMarkTaken: onMarkTaken,
            onDelete: onDelete,
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
      expect(find.text('Heartgard Plus'), findsOneWidget);
    });

    testWidgets('displays dosage', (tester) async {
      await tester.pumpWidget(buildCard(futureEntry));
      expect(find.text('1 tablet'), findsOneWidget);
    });

    testWidgets('displays frequency badge', (tester) async {
      await tester.pumpWidget(buildCard(futureEntry));
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('displays Mark Taken button', (tester) async {
      await tester.pumpWidget(buildCard(futureEntry));
      expect(find.text('Mark Taken'), findsOneWidget);
    });

    testWidgets('calls onMarkTaken when button pressed', (tester) async {
      var called = false;
      await tester.pumpWidget(
          buildCard(futureEntry, onMarkTaken: () => called = true));
      await tester.tap(find.text('Mark Taken'));
      expect(called, isTrue);
    });

    testWidgets('shows overdue status for past entries', (tester) async {
      final overdueEntry = futureEntry.copyWith(
          nextDueDate: DateTime.now().subtract(const Duration(days: 1)));
      await tester.pumpWidget(buildCard(overdueEntry));
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
          buildCard(futureEntry, onDelete: () => deleted = true));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete Entry'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('displays due date info for future entries', (tester) async {
      await tester.pumpWidget(buildCard(futureEntry));
      expect(find.textContaining('Due in'), findsOneWidget);
    });
  });
}
