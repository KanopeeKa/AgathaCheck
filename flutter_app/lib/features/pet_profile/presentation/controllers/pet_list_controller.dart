import '../../domain/entities/pet.dart';

class PetListController {
  String? orgFilter;

  List<String> getOrgNames(List<Pet> allPets) {
    final names = <String>{};
    for (final pet in allPets) {
      if (pet.organizationName != null && pet.organizationName!.isNotEmpty) {
        names.add(pet.organizationName!);
      }
    }
    return names.toList()..sort();
  }

  bool _isPersonalPet(Pet p) =>
      p.isShared ||
      p.organizationId == null ||
      (p.organizationName == null || p.organizationName!.isEmpty);

  List<Pet> filterPets(List<Pet> allPets) {
    if (orgFilter == null) return allPets;
    if (orgFilter == '_personal') {
      return allPets.where(_isPersonalPet).toList();
    }
    return allPets
        .where((p) => !p.isShared && p.organizationName == orgFilter)
        .toList();
  }

  List<Pet> getPersonalActive(List<Pet> filteredPets) {
    return filteredPets
        .where((p) => !p.passedAway && _isPersonalPet(p))
        .toList();
  }

  List<Pet> getPersonalPassed(List<Pet> filteredPets) {
    return filteredPets
        .where((p) => p.passedAway && _isPersonalPet(p))
        .toList();
  }

  Map<String, List<Pet>> getOrgGroups(List<Pet> filteredPets) {
    final groups = <String, List<Pet>>{};
    for (final pet in filteredPets) {
      if (!pet.passedAway &&
          pet.organizationName != null &&
          pet.organizationName!.isNotEmpty) {
        groups.putIfAbsent(pet.organizationName!, () => []).add(pet);
      }
    }
    return groups;
  }

  Map<String, List<Pet>> getOrgPassedGroups(List<Pet> filteredPets) {
    final groups = <String, List<Pet>>{};
    for (final pet in filteredPets) {
      if (pet.passedAway &&
          pet.organizationName != null &&
          pet.organizationName!.isNotEmpty) {
        groups.putIfAbsent(pet.organizationName!, () => []).add(pet);
      }
    }
    return groups;
  }

  List<Pet> getAllPassedAway(
      List<Pet> personalPassed, Map<String, List<Pet>> orgPassedGroups) {
    final all = <Pet>[...personalPassed];
    for (final pets in orgPassedGroups.values) {
      all.addAll(pets);
    }
    return all;
  }
}
