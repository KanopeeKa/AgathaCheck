import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/care_item/presentation/detail/care_item_info_section.dart';
import 'package:pet_profile_app/features/people/domain/entities/people_contact.dart';
import 'package:pet_profile_app/features/people/presentation/providers/people_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _EmptyPeopleContactsNotifier extends PeopleContactsNotifier {
  @override
  Future<List<PeopleContact>> build() async => [];
}

void main() {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peopleContactsProvider.overrideWith(_EmptyPeopleContactsNotifier.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CareItemInfoSection(entry: entry, muted: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Give with food'), findsOneWidget);
    expect(find.textContaining('Every'), findsNothing);
    expect(find.textContaining('Reminded'), findsNothing);
  });
}
