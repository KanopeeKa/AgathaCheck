import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/weight_tracking/sheets/weight_settings_edit_sheet.dart';
import 'package:pet_profile_app/features/experience/presentation/weight_tracking/widgets/weight_hub_settings_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_cache_freshness.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_list_fetch_result.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_viewer_role.dart';
import 'package:pet_profile_app/features/pet_profile/domain/repositories/pet_repository.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/pet_detail_actions.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_detail_viewer_context_provider.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_overview.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

const _pet = Pet(
  id: 'pet-1',
  name: 'Rex',
  species: 'Dog',
  weightReferenceValue: 4,
  weightReferenceAuthority: 'vet_target',
  weightManagementContext: 'vet_managed',
);

class _RecordingWeightRepo implements PetRepository {
  _RecordingWeightRepo({this.pets = const [_pet]});

  final List<Pet> pets;
  final List<Map<String, Object?>> weightContextCalls = [];

  @override
  Future<List<Pet>> getAllPets() async => pets;

  @override
  Future<PetListFetchResult> fetchAllPets() async => PetListFetchResult(
    pets: pets,
    source: PetListFetchSource.remote,
    freshness: PetCacheFreshness.fresh,
  );

  @override
  Future<Pet?> getPetById(String id) async =>
      pets.where((p) => p.id == id).firstOrNull;

  @override
  Future<Pet> addPet(Pet pet) async => pet;

  @override
  Future<Pet> updatePet(Pet pet) async => pet;

  @override
  Future<Pet> updatePetWeightContext({
    required String petId,
    double? weightReferenceValue,
    String? weightReferenceAuthority,
    required String weightManagementContext,
  }) async {
    weightContextCalls.add({
      'petId': petId,
      'weightReferenceValue': weightReferenceValue,
      'weightReferenceAuthority': weightReferenceAuthority,
      'weightManagementContext': weightManagementContext,
    });
    return pets.first.copyWith(
      weightReferenceValue: weightReferenceValue,
      weightReferenceAuthority: weightReferenceAuthority,
      weightManagementContext: weightManagementContext,
    );
  }

  @override
  Future<void> deletePet(String id) async {}

  @override
  Future<void> deletePetWithDataCleanup(String id) async {}

  @override
  Future<bool> markPassedAway(Pet pet) async => false;
}

Widget _wrap({
  required Widget child,
  required _RecordingWeightRepo repo,
  Set<PetDetailAction> actions = const {PetDetailAction.editProfile},
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      petRepositoryProvider.overrideWithValue(repo),
      allPetsIncludingOrgProvider.overrideWith((ref) async => repo.pets),
      petDetailViewerContextProvider('pet-1').overrideWithValue(
        PetDetailContext(
          role: PetViewerRole.guardian,
          experience: AppExperience.petCare,
          actions: actions,
          isPolicyResolved: true,
        ),
      ),
      weightOverviewProvider.overrideWith(
        (ref, petId) async => WeightOverview(petId: petId, routines: []),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('WT3 sheet save sends three weight-context fields', (
    tester,
  ) async {
    final repo = _RecordingWeightRepo();
    await tester.pumpWidget(
      _wrap(
        child: WeightSettingsEditSheet(pet: _pet),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('weight_settings_reference_value_field')),
      '5.5',
    );
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.weightContextCalls, hasLength(1));
    final call = repo.weightContextCalls.single;
    expect(call['petId'], 'pet-1');
    expect(call['weightReferenceValue'], 5.5);
    expect(call['weightReferenceAuthority'], 'vet_target');
    expect(call['weightManagementContext'], 'vet_managed');
    expect(find.byType(WeightSettingsEditSheet), findsNothing);
  });

  testWidgets('WT4 sheet Cancel closes without saving', (tester) async {
    final repo = _RecordingWeightRepo();
    await tester.pumpWidget(
      _wrap(
        child: WeightSettingsEditSheet(pet: _pet),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('weight_settings_reference_value_field')),
      '9',
    );
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.weightContextCalls, isEmpty);
    expect(find.byType(WeightSettingsEditSheet), findsNothing);
  });

  testWidgets('WT6 card hides Edit when profile is read-only', (tester) async {
    final repo = _RecordingWeightRepo();
    await tester.pumpWidget(
      _wrap(
        child: const WeightHubSettingsCard(petId: 'pet-1'),
        repo: repo,
        actions: const {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weight_hub_settings_card')), findsOneWidget);
    expect(find.text('4.0 kg'), findsOneWidget);
    expect(find.byKey(const Key('weight_hub_settings_edit')), findsNothing);
  });

  testWidgets('WT4 card shows settings from pet fields', (tester) async {
    final repo = _RecordingWeightRepo();
    await tester.pumpWidget(
      _wrap(
        child: const WeightHubSettingsCard(petId: 'pet-1'),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vet target'), findsOneWidget);
    expect(find.byKey(const Key('weight_hub_settings_edit')), findsOneWidget);
  });
}
