import '../../../pet_profile/domain/entities/pet.dart';

const _activeFosterStatuses = {
  'in_progress',
  'waiting_adoption_confirmation',
  'pending_adoption_conditions',
};

extension PetCustodyHelpers on Pet {
  bool get isFosteredOrgPet =>
      organizationId != null &&
      fosterPlacementStatus != null &&
      _activeFosterStatuses.contains(fosterPlacementStatus);
}
