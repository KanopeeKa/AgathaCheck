import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';

class PetProfileController {
  final WidgetRef ref;
  PetProfileController(this.ref);

  List getVets() {
    final vetsAsync = ref.watch(vetListProvider);
    return vetsAsync.valueOrNull ?? [];
  }

  dynamic getAssignedVet(Pet pet) {
    final vets = getVets();
    return (pet.vetId != null && pet.vetId!.isNotEmpty)
        ? vets.where((v) => v.id == pet.vetId).firstOrNull
        : null;
  }

  double? getDisplayWeight(Pet pet) {
    final latestWeightAsync = ref.watch(latestWeightProvider(pet.id));
    final latestWeight = latestWeightAsync.valueOrNull;
    return latestWeight?.weight ?? pet.weight;
  }
}
