import '../../domain/entities/pet.dart';

class PetListController {
  String? orgFilter;

  /// Clears [orgFilter] when it targets an organisation that is no longer present.
  void syncOrgFilter(List<String> orgNames) {
    if (orgFilter != null &&
        orgFilter != '_personal' &&
        orgFilter != '_fostered' &&
        !orgNames.contains(orgFilter)) {
      orgFilter = null;
    }
  }

  List<String> getOrgNames(List<Pet> allPets) {
    final names = <String>{};
    for (final pet in allPets) {
      if (!pet.isFoster &&
          pet.organizationName != null &&
          pet.organizationName!.isNotEmpty) {
        names.add(pet.organizationName!);
      }
    }
    return names.toList()..sort();
  }

  bool hasFosteredPets(List<Pet> allPets) => allPets.any((p) => p.isFoster);

  bool _isPersonalPet(Pet p) =>
      !p.isFoster &&
      (p.isShared ||
          p.organizationId == null ||
          (p.organizationName == null || p.organizationName!.isEmpty));

  List<Pet> filterPets(List<Pet> allPets) {
    if (orgFilter == null) return allPets;
    if (orgFilter == '_personal') {
      return allPets.where(_isPersonalPet).toList();
    }
    if (orgFilter == '_fostered') {
      return allPets.where((p) => p.isFoster).toList();
    }
    return allPets
        .where(
          (p) => !p.isShared && !p.isFoster && p.organizationName == orgFilter,
        )
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

  List<Pet> getFosteredActive(List<Pet> filteredPets) {
    return filteredPets.where((p) => !p.passedAway && p.isFoster).toList();
  }

  List<Pet> getFosteredPassed(List<Pet> filteredPets) {
    return filteredPets.where((p) => p.passedAway && p.isFoster).toList();
  }

  /// Pets visible in the guardian shell (personal + fostered; no org inventory).
  List<Pet> guardianShellPets(List<Pet> allPets) {
    return allPets.where((p) => _isPersonalPet(p) || p.isFoster).toList();
  }

  Map<String, List<Pet>> getOrgGroups(List<Pet> filteredPets) {
    final groups = <String, List<Pet>>{};
    for (final pet in filteredPets) {
      if (!pet.passedAway &&
          !pet.isFoster &&
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
          !pet.isFoster &&
          pet.organizationName != null &&
          pet.organizationName!.isNotEmpty) {
        groups.putIfAbsent(pet.organizationName!, () => []).add(pet);
      }
    }
    return groups;
  }

  List<Pet> getAllPassedAway(
    List<Pet> personalPassed,
    List<Pet> fosteredPassed,
    Map<String, List<Pet>> orgPassedGroups,
  ) {
    final all = <Pet>[...personalPassed, ...fosteredPassed];
    for (final pets in orgPassedGroups.values) {
      all.addAll(pets);
    }
    return all;
  }
}
