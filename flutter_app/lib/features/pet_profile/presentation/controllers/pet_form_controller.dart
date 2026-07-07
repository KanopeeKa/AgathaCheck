import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../../domain/entities/pet.dart';
import 'pet_form_outcomes.dart';

class PetFormController {
  PetFormState _state;

  PetFormController() : _state = PetFormState();

  PetFormState get state => _state;
  set state(PetFormState newState) => _state = newState;

  void populateForm(Pet pet) {
    _state = _state.copyWith(
      name: pet.name,
      breed: pet.breed,
      weight: pet.weight?.toString() ?? '',
      bio: pet.bio,
      insurance: pet.insurance,
      chipId: pet.chipId,
      selectedSpecies: pet.species,
      selectedGender: pet.gender,
      photoBase64: pet.photoPath,
      selectedVetId: pet.vetId,
      existingColorValue: pet.colorValue,
      dateOfBirth: pet.dateOfBirth,
      neuteredDate: pet.neuteredDate,
      isNeutered: pet.neuteredDate != null ? true : null,
      neuterDismissed: pet.neuterDismissed,
      chipDismissed: pet.chipDismissed,
      passedAway: pet.passedAway,
      isShared: pet.isShared,
      selectedOrgId: pet.organizationId,
    );
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _state = _state.copyWith(photoBase64: base64Encode(bytes));
      }
    } catch (e) {
      // Handle error in UI
    }
  }

  void setSelectedOrgId(String? orgId) =>
      _state = _state.copyWith(selectedOrgId: orgId);

  void setShowWeightInput(bool show) =>
      _state = _state.copyWith(showWeightInput: show);

  void setNewWeight(String weight) =>
      _state = _state.copyWith(newWeight: weight);

  /// Validates form state and creates or updates the pet via [deps].
  Future<PetFormSubmitOutcome> submit(
    PetFormSubmitDeps deps, {
    required bool isEditing,
    String? petId,
  }) async {
    if (state.name.trim().isEmpty) {
      return PetFormSubmitValidationFailed(
        PetFormSubmitValidation.nameRequired,
      );
    }

    final weightError = _validateWeight(isEditing: isEditing);
    if (weightError != null) {
      return PetFormSubmitValidationFailed(weightError);
    }

    final weight = _parsedWeight(isEditing: isEditing);

    try {
      if (isEditing) {
        if (petId == null) {
          return PetFormSubmitError(StateError('petId required for edit'));
        }
        final pets = deps.readPets();
        final existing = pets.where((p) => p.id == petId).firstOrNull;
        if (existing == null) {
          return PetFormSubmitValidationFailed(
            PetFormSubmitValidation.petNotFound,
          );
        }

        final updated = existing.copyWith(
          name: state.name.trim(),
          species: state.selectedSpecies,
          breed: state.breed.trim(),
          dateOfBirth: state.dateOfBirth,
          weight: weight,
          gender: state.selectedGender,
          bio: state.bio.trim(),
          insurance: state.insurance.trim(),
          neuteredDate: state.neuteredDate,
          neuterDismissed: state.neuterDismissed,
          chipId: state.chipId.trim(),
          chipDismissed: state.chipDismissed,
          photoPath: state.photoBase64,
          vetId: state.selectedVetId,
          passedAway: state.passedAway,
          organizationId: state.selectedOrgId,
          clearVetId: state.selectedVetId == null,
          clearGender: state.selectedGender == null,
          clearNeuteredDate: state.neuteredDate == null,
          clearDateOfBirth: state.dateOfBirth == null,
        );
        await deps.updatePet(updated);
        return PetFormSubmitSuccess(petId: petId, orgId: state.selectedOrgId);
      }

      await deps.addPet(
        name: state.name.trim(),
        species: state.selectedSpecies,
        breed: state.breed.trim(),
        dateOfBirth: state.dateOfBirth,
        weight: weight,
        gender: state.selectedGender,
        bio: state.bio.trim(),
        insurance: state.insurance.trim(),
        neuteredDate: state.neuteredDate,
        neuterDismissed: state.neuterDismissed,
        chipId: state.chipId.trim(),
        chipDismissed: state.chipDismissed,
        photoPath: state.photoBase64,
        vetId: state.selectedVetId,
        organizationId: state.selectedOrgId,
      );

      final orgId = state.selectedOrgId;
      if (orgId != null) {
        deps.invalidateOrgPets?.call(orgId);
      }
      return PetFormSubmitSuccess(orgId: orgId);
    } catch (e) {
      return PetFormSubmitError(e);
    }
  }

  PetFormSubmitValidation? _validateWeight({required bool isEditing}) {
    final weightStr = isEditing ? state.weight.trim() : state.newWeight.trim();
    if (weightStr.isEmpty) return null;

    final parsed = double.tryParse(weightStr);
    if (parsed == null) return PetFormSubmitValidation.invalidWeight;
    if (isEditing) {
      if (parsed < 0) return PetFormSubmitValidation.invalidWeight;
    } else if (parsed <= 0) {
      return PetFormSubmitValidation.invalidWeight;
    }
    return null;
  }

  double? _parsedWeight({required bool isEditing}) {
    final weightStr = isEditing ? state.weight.trim() : state.newWeight.trim();
    if (weightStr.isEmpty) return null;
    return double.tryParse(weightStr);
  }
}

class PetFormState {
  final String name;
  final String breed;
  final String weight;
  final String newWeight;
  final bool showWeightInput;
  final String bio;
  final String insurance;
  final String chipId;
  final String selectedSpecies;
  final String? selectedGender;
  final String? photoBase64;
  final String? selectedVetId;
  final int? existingColorValue;
  final DateTime? dateOfBirth;
  final DateTime? neuteredDate;
  final bool? isNeutered;
  final bool neuterDismissed;
  final bool chipDismissed;
  final bool passedAway;
  final bool isShared;
  final String? selectedOrgId;

  PetFormState({
    this.name = '',
    this.breed = '',
    this.weight = '',
    this.newWeight = '',
    this.showWeightInput = false,
    this.bio = '',
    this.insurance = '',
    this.chipId = '',
    this.selectedSpecies = '',
    this.selectedGender,
    this.photoBase64,
    this.selectedVetId,
    this.existingColorValue,
    this.dateOfBirth,
    this.neuteredDate,
    this.isNeutered,
    this.neuterDismissed = false,
    this.chipDismissed = false,
    this.passedAway = false,
    this.isShared = false,
    this.selectedOrgId,
  });

  PetFormState copyWith({
    String? name,
    String? breed,
    String? weight,
    String? newWeight,
    bool? showWeightInput,
    String? bio,
    String? insurance,
    String? chipId,
    String? selectedSpecies,
    String? selectedGender,
    String? photoBase64,
    String? selectedVetId,
    int? existingColorValue,
    DateTime? dateOfBirth,
    DateTime? neuteredDate,
    bool? isNeutered,
    bool? neuterDismissed,
    bool? chipDismissed,
    bool? passedAway,
    bool? isShared,
    String? selectedOrgId,
  }) {
    return PetFormState(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
      newWeight: newWeight ?? this.newWeight,
      showWeightInput: showWeightInput ?? this.showWeightInput,
      bio: bio ?? this.bio,
      insurance: insurance ?? this.insurance,
      chipId: chipId ?? this.chipId,
      selectedSpecies: selectedSpecies ?? this.selectedSpecies,
      selectedGender: selectedGender ?? this.selectedGender,
      photoBase64: photoBase64 ?? this.photoBase64,
      selectedVetId: selectedVetId ?? this.selectedVetId,
      existingColorValue: existingColorValue ?? this.existingColorValue,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      neuteredDate: neuteredDate ?? this.neuteredDate,
      isNeutered: isNeutered ?? this.isNeutered,
      neuterDismissed: neuterDismissed ?? this.neuterDismissed,
      chipDismissed: chipDismissed ?? this.chipDismissed,
      passedAway: passedAway ?? this.passedAway,
      isShared: isShared ?? this.isShared,
      selectedOrgId: selectedOrgId ?? this.selectedOrgId,
    );
  }
}
