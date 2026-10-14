import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/care_taxonomy.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/detail/care_item_info_section.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _EmptyRosterNotifier extends RosterNotifier {
  @override
  Future<Roster> build() async =>
      const Roster(households: [], contacts: [], pendingInvites: []);
}

void main() {
  const pet = Pet(
    id: 'pet-1',
    name: 'Buddy',
    species: 'Dog',
    colorValue: 0xFF2196F3,
  );

  Future<void> pumpSection(WidgetTester tester, HealthEntry entry) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rosterProvider.overrideWith(_EmptyRosterNotifier.new)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CareItemInfoSection(entry: entry, muted: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('CareItemInfoSection omits recurrence copy owned by schedule', (
    tester,
  ) async {
    final entry = HealthEntry(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Heartworm',
      type: HealthEntryType.preventive,
      frequency: HealthFrequency.monthly,
      frequencyInterval: 1,
      startDate: DateTime(2025, 1, 1),
      nextDueDate: DateTime(2025, 6, 1),
      notes: 'Give with food',
    );

    await pumpSection(tester, entry);

    expect(find.text('Give with food'), findsOneWidget);
    expect(find.textContaining('Every'), findsNothing);
    expect(find.textContaining('Reminded'), findsNothing);
    expect(find.byKey(const Key('care_item_details_identity')), findsOneWidget);
    expect(find.textContaining('Heartworm'), findsOneWidget);
  });

  testWidgets('shows Where row when careSetting is set', (tester) async {
    final entry = HealthEntry(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Apoquel',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.daily,
      frequencyInterval: 1,
      startDate: DateTime(2025, 1, 1),
      careFamily: CareFamily.medication,
      careSetting: CareSetting.vet,
      dosage: '16 mg',
    );

    await pumpSection(tester, entry);

    expect(find.text('At the vet'), findsOneWidget);
    expect(find.text('16 mg'), findsOneWidget);
    expect(find.text('Not set'), findsNothing);
    expect(find.text('Care category'), findsNothing);
  });
}
