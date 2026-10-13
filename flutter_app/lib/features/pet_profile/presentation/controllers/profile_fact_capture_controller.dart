import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pet.dart';
import '../../domain/entities/profile_fact_status.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_form/pet_form_neutered_section.dart';

/// Persists profile fact answers from the inline capture sheet.
class ProfileFactCaptureController {
  ProfileFactCaptureController(this.ref);

  final WidgetRef ref;

  Future<void> saveNeuterCapture(
    Pet pet,
    PetNeuterSelection selection, {
    DateTime? neuteredDate,
  }) async {
    final status = _statusWire(selection);
    final updated = pet.copyWith(
      neuterStatus: status,
      neuterStatusSource: 'user',
      neuteredDate: selection == PetNeuterSelection.yes ? neuteredDate : null,
      clearNeuteredDate: selection != PetNeuterSelection.yes,
    );
    await ref.read(petListProvider.notifier).updatePet(updated);
  }

  Future<void> saveChipCapture(
    Pet pet,
    PetNeuterSelection selection, {
    String chipId = '',
  }) async {
    final status = _statusWire(selection);
    final trimmedChip = chipId.trim();
    final updated = pet.copyWith(
      identificationStatus: status,
      identificationStatusSource: 'user',
      chipId: selection == PetNeuterSelection.yes ? trimmedChip : '',
    );
    await ref.read(petListProvider.notifier).updatePet(updated);
  }

  String _statusWire(PetNeuterSelection selection) {
    switch (selection) {
      case PetNeuterSelection.yes:
        return profileFactStatusYes;
      case PetNeuterSelection.no:
        return profileFactStatusNo;
      case PetNeuterSelection.unknown:
        return profileFactStatusUnknown;
    }
  }
}
