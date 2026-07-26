import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';

/// Active personal pets (owned + shared) for the guardian dashboard, oldest first.
List<Pet> guardianDashboardPersonalPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final personal = shellPets
      .where((p) => !p.passedAway && !p.isFoster)
      .toList();
  sortPetsByCreatedAt(personal);
  return personal;
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

/// Whether the guardian has any active shell pets (personal or foster).
bool guardianDashboardHasAnyPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  return shellPets.any((p) => !p.passedAway);
}
