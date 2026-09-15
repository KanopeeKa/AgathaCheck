import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence_pet_carer.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/away_plan_copy.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('carerCoverageSummary maps all_have_carers copy key', () {
    final text = AwayPlanCopy.carerCoverageSummary(
      l,
      const CarerCoverageFact(
        state: 'all_have_carers',
        petsWithCarer: 2,
        petsTotal: 2,
        copyKey: 'awayPlanningCarerCoverageAllHaveCarers',
      ),
    );
    expect(text, l.awayPlanningCarerCoverageAllHaveCarers);
  });

  test('careCoverageSummary maps has_items_to_review count', () {
    final text = AwayPlanCopy.careCoverageSummary(
      l,
      const CareCoverageFact(
        policyVersion: '1',
        coverageState: 'has_items_to_review',
        reasonCodes: const [],
        reassuranceAvailable: true,
        copyKey: 'careContextCoverageHasItemsToReview',
        copyCount: 3,
      ),
    );
    expect(text, l.careContextCoverageHasItemsToReview(3));
  });

  test('petCarerLabel maps shared_user and note_only carers', () {
    expect(
      AwayPlanCopy.petCarerLabel(
        l,
        const PlannedAbsencePetCarer(
          petId: 'pet-1',
          carerKind: 'shared_user',
          carerName: 'Sarah M.',
        ),
      ),
      l.awayPlanningCarerSharedAccess('Sarah M.'),
    );
    expect(
      AwayPlanCopy.petCarerLabel(
        l,
        const PlannedAbsencePetCarer(
          petId: 'pet-2',
          carerKind: 'note_only',
          carerName: 'Tom',
        ),
      ),
      l.awayPlanningCarerNoteOnly('Tom'),
    );
    expect(
      AwayPlanCopy.petCarerLabel(
        l,
        const PlannedAbsencePetCarer(
          petId: 'pet-4',
          carerKind: 'note_only',
          carerName: 'Tom',
          carerNote: 'Neighbour',
        ),
      ),
      l.awayPlanningCarerNoteOnlyWithNote('Tom', 'Neighbour'),
    );
    expect(
      AwayPlanCopy.petCarerLabel(
        l,
        const PlannedAbsencePetCarer(petId: 'pet-3', carerRemoved: true),
      ),
      l.awayPlanningCarerRemoved,
    );
  });
}
