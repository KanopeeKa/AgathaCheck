import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

/// Dependencies for [PetFormController.submit], injectable in tests.
class PetFormSubmitDeps {
  const PetFormSubmitDeps({
    required this.readPets,
    required this.addPet,
    required this.updatePet,
    this.invalidateOrgPets,
  });

  final List<Pet> Function() readPets;
  final Future<void> Function({
    required String name,
    required String species,
    String breed,
    DateTime? dateOfBirth,
    double? weight,
    String? gender,
    String bio,
    String insurance,
    DateTime? neuteredDate,
    bool neuterDismissed,
    String chipId,
    bool chipDismissed,
    String? photoPath,
    String? vetId,
    String? organizationId,
  })
  addPet;
  final Future<void> Function(Pet pet) updatePet;
  final void Function(String orgId)? invalidateOrgPets;

  factory PetFormSubmitDeps.fromWidgetRef(WidgetRef ref) {
    return PetFormSubmitDeps(
      readPets: () => ref.read(petListProvider).valueOrNull ?? [],
      addPet:
          ({
            required String name,
            required String species,
            String breed = '',
            DateTime? dateOfBirth,
            double? weight,
            String? gender,
            String bio = '',
            String insurance = '',
            DateTime? neuteredDate,
            bool neuterDismissed = false,
            String chipId = '',
            bool chipDismissed = false,
            String? photoPath,
            String? vetId,
            String? organizationId,
          }) async {
            await ref
                .read(petListProvider.notifier)
                .addPet(
                  name: name,
                  species: species,
                  breed: breed,
                  dateOfBirth: dateOfBirth,
                  weight: weight,
                  gender: gender,
                  bio: bio,
                  insurance: insurance,
                  neuteredDate: neuteredDate,
                  neuterDismissed: neuterDismissed,
                  chipId: chipId,
                  chipDismissed: chipDismissed,
                  photoPath: photoPath,
                  vetId: vetId,
                  organizationId: organizationId,
                );
          },
      updatePet: (pet) => ref.read(petListProvider.notifier).updatePet(pet),
      invalidateOrgPets: (orgId) => ref.invalidate(orgPetsProvider(orgId)),
    );
  }

  factory PetFormSubmitDeps.fromRef(Ref ref) {
    return PetFormSubmitDeps(
      readPets: () => ref.read(petListProvider).valueOrNull ?? [],
      addPet:
          ({
            required String name,
            required String species,
            String breed = '',
            DateTime? dateOfBirth,
            double? weight,
            String? gender,
            String bio = '',
            String insurance = '',
            DateTime? neuteredDate,
            bool neuterDismissed = false,
            String chipId = '',
            bool chipDismissed = false,
            String? photoPath,
            String? vetId,
            String? organizationId,
          }) async {
            await ref
                .read(petListProvider.notifier)
                .addPet(
                  name: name,
                  species: species,
                  breed: breed,
                  dateOfBirth: dateOfBirth,
                  weight: weight,
                  gender: gender,
                  bio: bio,
                  insurance: insurance,
                  neuteredDate: neuteredDate,
                  neuterDismissed: neuterDismissed,
                  chipId: chipId,
                  chipDismissed: chipDismissed,
                  photoPath: photoPath,
                  vetId: vetId,
                  organizationId: organizationId,
                );
          },
      updatePet: (pet) => ref.read(petListProvider.notifier).updatePet(pet),
      invalidateOrgPets: (orgId) => ref.invalidate(orgPetsProvider(orgId)),
    );
  }
}

sealed class PetFormSubmitOutcome {}

enum PetFormSubmitValidation { nameRequired, invalidWeight, petNotFound }

enum PetFormPhotoError { tooLarge, unsupportedType, pickFailed }

enum PetFormSubmitErrorKind {
  photoTooLarge,
  photoUnsupportedType,
  photoUploadFailed,
  networkError,
  unauthorized,
  saveFailed,
}

sealed class PetFormPickImageOutcome {}

class PetFormPickImageSuccess extends PetFormPickImageOutcome {}

class PetFormPickImageFailed extends PetFormPickImageOutcome {
  PetFormPickImageFailed(this.error);
  final PetFormPhotoError error;
}

class PetFormSubmitValidationFailed extends PetFormSubmitOutcome {
  PetFormSubmitValidationFailed(this.reason);
  final PetFormSubmitValidation reason;
}

class PetFormSubmitSuccess extends PetFormSubmitOutcome {
  PetFormSubmitSuccess({this.petId, this.orgId});

  final String? petId;
  final String? orgId;
}

class PetFormSubmitError extends PetFormSubmitOutcome {
  PetFormSubmitError(this.kind, {Object? debugDetail}) : error = debugDetail;

  final PetFormSubmitErrorKind kind;
  final Object? error;
}
