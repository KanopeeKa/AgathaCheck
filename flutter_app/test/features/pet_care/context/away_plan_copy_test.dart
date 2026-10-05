import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence_pet_carer.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
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

  test('handoverContactLines uses pet people relationships', () {
    final lines = AwayPlanCopy.handoverContactLines(
      l,
      const PetPeople(
        petId: 'p1',
        petName: 'Buddy',
        scope: 'owner',
        owner: PetPeopleOwner(userId: 'u1', displayName: 'Alex'),
        householdMembers: const [],
        relationships: [
          PetRelationship(
            id: 'r1',
            petId: 'p1',
            contactId: 'c1',
            relationshipKind: RelationshipKind.primaryVet,
            isPrimary: true,
            active: true,
            contactKind: 'organisation',
            contactName: 'Greenhill',
            contactPhone: '555-0100',
          ),
        ],
      ),
    );
    expect(lines, hasLength(1));
    expect(lines.single, contains('Greenhill'));
    expect(lines.single, contains('555-0100'));
  });

  test('petCarerLabel maps shared_user and note_only carers', () {
    expect(
      AwayPlanCopy.petCarerLabel(
        l,
        const PlannedAbsencePetCarer(
          petId: 'pet-1',
          carerKind: 'shared_user',
          carerName: 'Sarah M.',
          carerState: 'set',
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
          carerState: 'set',
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
          carerState: 'set',
        ),
      ),
      l.awayPlanningCarerNoteOnlyWithNote('Tom', 'Neighbour'),
    );
    expect(
      AwayPlanCopy.petCarerLabel(
        l,
        const PlannedAbsencePetCarer(
          petId: 'pet-3',
          carerState: 'unavailable',
          carerRemoved: true,
        ),
      ),
      l.awayPlanningCarerRemoved,
    );
  });
}
