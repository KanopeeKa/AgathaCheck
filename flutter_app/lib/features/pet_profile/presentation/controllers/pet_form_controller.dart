import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/pet.dart';

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
}

class PetFormState {
  final String name;
  final String breed;
  final String weight;
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
  final String? selectedOrgId;

  PetFormState({
    this.name = '',
    this.breed = '',
    this.weight = '',
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
    this.selectedOrgId,
  });

  PetFormState copyWith({
    String? name,
    String? breed,
    String? weight,
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
    String? selectedOrgId,
  }) {
    return PetFormState(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
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
      selectedOrgId: selectedOrgId ?? this.selectedOrgId,
    );
  }
}
