import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';

/// Active owned pets (not shared or foster) for the guardian dashboard, oldest first.
List<Pet> guardianDashboardPersonalPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final owned = controller.getOwnedPets(shellPets);
  sortPetsByCreatedAt(owned);
  return owned;
}

/// Active foster pets for the guardian dashboard, oldest first.
List<Pet> guardianDashboardFosterPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final fostered = shellPets.where((p) => !p.passedAway && p.isFoster).toList();
  sortPetsByCreatedAt(fostered);
  return fostered;
}

/// Active shared pets for the guardian dashboard, oldest first.
List<Pet> guardianDashboardSharedPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final shared = shellPets.where((p) => !p.passedAway && p.isShared).toList();
  sortPetsByCreatedAt(shared);
  return shared;
}

/// Whether the guardian has any active shell pets (personal or foster).
bool guardianDashboardHasAnyPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  return shellPets.any((p) => !p.passedAway);
}
