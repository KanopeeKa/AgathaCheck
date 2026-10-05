import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_absence_context_model.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/care_item_absence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/core/care/care_item_observation_section.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/care_item/presentation/detail/care_item_detail_body.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/widgets/weight_care_item_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _EmptyWeightEntriesNotifier extends WeightEntriesNotifier {
  @override
  Future<List<WeightEntry>> build(String arg) async => [];
}

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

  testWidgets(
    'FW-17 weigh-in routine shows weight section; medication does not',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Widget buildFor(HealthEntry healthEntry) {
        return ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('http://test.local'),
            careItemAbsenceContextProvider(healthEntry.id).overrideWith(
              (ref) async => HealthEntryAbsenceContext(
                healthEntryId: healthEntry.id,
                petId: 'pet-1',
                absences: [],
              ),
            ),
            entryOccurrencesProvider(
              healthEntry.id,
            ).overrideWith((ref) async => []),
            careItemObservationSectionProvider.overrideWith(
              (ref) =>
                  (
                    context, {
                    required petId,
                    required entryId,
                    required observationKind,
                  }) {
                    if (observationKind == 'numeric_weight') {
                      return WeightCareItemSection(
                        petId: petId,
                        entryId: entryId,
                      );
                    }
                    return null;
                  },
            ),
            weightEntriesNotifierProvider.overrideWith(
              () => _EmptyWeightEntriesNotifier(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CareItemDetailBody(
                petId: 'pet-1',
                entry: healthEntry,
                pet: pet,
                history: const <HealthHistoryEntry>[],
                isClosed: false,
                isEstablished: false,
                onSeeHistory: () {},
              ),
            ),
          ),
        );
      }

      final weightEntry = HealthEntry(
        id: 'weight-entry',
        petId: 'pet-1',
        name: 'Weekly weigh-in',
        type: HealthEntryType.preventive,
        frequency: HealthFrequency.monthly,
        frequencyInterval: 1,
        startDate: DateTime(2025, 1, 1),
        nextDueDate: DateTime(2025, 6, 1),
        careFamily: CareFamily.weightMonitoring,
      );

      await tester.pumpWidget(buildFor(weightEntry));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('weight_care_item_section')), findsOneWidget);
    },
  );

  testWidgets('FW-17 medication care item hides weight section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final medicationEntry = HealthEntry(
      id: 'med-entry',
      petId: 'pet-1',
      name: 'Heartworm',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      frequencyInterval: 1,
      startDate: DateTime(2025, 1, 1),
      nextDueDate: DateTime(2025, 6, 1),
      careFamily: CareFamily.medication,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('med-entry').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'med-entry',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('med-entry').overrideWith((ref) async => []),
          careItemObservationSectionProvider.overrideWith(
            (ref) =>
                (
                  context, {
                  required petId,
                  required entryId,
                  required observationKind,
                }) {
                  if (observationKind == 'numeric_weight') {
                    return WeightCareItemSection(
                      petId: petId,
                      entryId: entryId,
                    );
                  }
                  return null;
                },
          ),
          weightEntriesNotifierProvider.overrideWith(
            () => _EmptyWeightEntriesNotifier(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: medicationEntry,
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
    expect(find.byKey(const Key('weight_care_item_section')), findsNothing);
  });
}
