import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_vet_contacts_provider.dart';

class PetProfileController {
  final WidgetRef ref;
  PetProfileController(this.ref);

  List<PetVetOption> getVets() {
    final vetsAsync = ref.watch(petVetOptionsProvider);
    return vetsAsync.valueOrNull ?? [];
  }

  PetVetOption? getAssignedVet(Pet pet) {
    return findPetVetOption(getVets(), pet.vetId);
  }

  double? getDisplayWeight(Pet pet) => pet.weight;
}
