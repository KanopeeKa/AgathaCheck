import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/pet_event_entry_list.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  final dateFormat = DateFormat('dd MMM yy');
  final l = lookupAppLocalizations(const Locale('en'));

  Widget buildList(List<HealthEntry> entries) {
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
        body: PetEventEntryList(
          entries: entries,
          petId: 'pet-1',
          onEntryTap: (_) {},
        ),
      ),
    );
  }

  final baseEntry = HealthEntry(
    id: '1',
    petId: 'pet-1',
    name: 'Heartgard Plus',
    type: HealthEntryType.medication,
    dosage: '1 tablet',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().add(const Duration(days: 5)),
  );

  testWidgets('shows due date without overdue label', (tester) async {
    final overdueEntry = baseEntry.copyWith(
      nextDueDate: DateTime.now().subtract(const Duration(days: 2)),
    );

    await tester.pumpWidget(buildList([overdueEntry]));
    await tester.pumpAndSettle();

    expect(
      find.text(dateFormat.format(overdueEntry.nextDueDate!)),
      findsOneWidget,
    );
    expect(find.text('Overdue'), findsNothing);
  });

  testWidgets('shows doneOn for completed entries', (tester) async {
    final completedOn = DateTime(2025, 6, 3);
    final completedEntry = HealthEntry(
      id: '2',
      petId: 'pet-1',
      name: 'Rabies vaccine',
      type: HealthEntryType.preventive,
      frequency: HealthFrequency.once,
      startDate: DateTime(2025, 1, 1),
      completedOn: completedOn,
      nextDueDate: DateTime(9999, 12, 31),
    );

    await tester.pumpWidget(buildList([completedEntry]));
    await tester.pumpAndSettle();

    expect(find.text(l.doneOn(dateFormat.format(completedOn))), findsOneWidget);
    expect(find.text('Completed'), findsNothing);
  });
}
