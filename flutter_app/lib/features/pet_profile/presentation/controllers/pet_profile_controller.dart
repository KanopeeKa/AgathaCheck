import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../people/people.dart';
import '../../domain/entities/pet.dart';

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
