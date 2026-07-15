import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_list/due_event_row.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  final pet = const Pet(id: 'pet-1', name: 'Bella', species: 'Dog');
  final overdueEntry = HealthEntry(
    id: 'entry-1',
    petId: 'pet-1',
    name: 'Heartworm',
    type: HealthEntryType.preventive,
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2024, 1, 1),
    nextDueDate: DateTime(2020, 1, 1),
  );

  testWidgets('shows inline action buttons when enabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DueEventRow(
              entry: overdueEntry,
              pet: pet,
              showInlineActions: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('due_event_open_entry-1')), findsOneWidget);
    expect(find.byKey(const Key('due_event_snooze_entry-1')), findsOneWidget);
    expect(find.byKey(const Key('due_event_done_entry-1')), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Bella'), findsOneWidget);
  });

  testWidgets('hides inline actions when disabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DueEventRow(
              entry: overdueEntry,
              pet: pet,
              showInlineActions: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('due_event_open_entry-1')), findsNothing);
    expect(find.text('Open'), findsNothing);
  });
}
