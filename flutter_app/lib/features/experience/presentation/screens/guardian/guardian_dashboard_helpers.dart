import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';

/// Sort key for dashboard pet preview: owned → shared → foster, then name.
int guardianDashboardPetRank(Pet pet) {
  if (pet.isFoster) return 2;
  if (pet.isShared) return 1;
  return 0;
}

/// Active guardian-shell pets for the My Pets preview (max [limit]).
List<Pet> guardianDashboardPreviewPets(
  List<Pet> allPets,
  PetListController controller, {
  int limit = 4,
}) {
  final shellPets = controller.guardianShellPets(allPets);
  final active = shellPets.where((p) => !p.passedAway).toList()
    ..sort((a, b) {
      final rank = guardianDashboardPetRank(
        a,
      ).compareTo(guardianDashboardPetRank(b));
      if (rank != 0) return rank;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  if (active.length <= limit) return active;
  return active.sublist(0, limit);
}

/// Whether the guardian has more active shell pets than the dashboard preview cap.
bool guardianDashboardHasMorePets(
  List<Pet> allPets,
  PetListController controller, {
  int limit = 4,
}) {
  final shellPets = controller.guardianShellPets(allPets);
  final activeCount = shellPets.where((p) => !p.passedAway).length;
  return activeCount > limit;
}
