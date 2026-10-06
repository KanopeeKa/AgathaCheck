import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/people/people.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

class PetProfileController {
  final WidgetRef ref;
  PetProfileController(this.ref);

  String? primaryVetContactId(Pet pet) {
    final petPeople = ref.watch(petPeopleProvider(pet.id)).valueOrNull;
    return primaryVetRelationship(petPeople)?.contactId;
  }

  String? primaryVetDisplayName(Pet pet) {
    final contactId = primaryVetContactId(pet);
    if (contactId == null) return null;
    return ref.watch(personSummaryProvider(contactId))?.name;
  }

  double? getDisplayWeight(Pet pet) => pet.weight;
}
