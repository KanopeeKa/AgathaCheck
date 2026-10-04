import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_absence_context_model.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/care_item_absence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/features/care_item/presentation/detail/care_item_detail_body.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const pet = Pet(
    id: 'pet-1',
    name: 'Bella',
    species: 'Dog',
    colorValue: 0xFF2196F3,
  );

  final entry = HealthEntry(
    id: 'entry-1',
    petId: 'pet-1',
    name: 'Heartworm',
    type: HealthEntryType.preventive,
    frequency: HealthFrequency.monthly,
    frequencyInterval: 1,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 6, 1),
  );

  testWidgets('CareItemDetailBody uses two columns at wide breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('care_item_detail_two_column')),
      findsOneWidget,
    );
  });
}
