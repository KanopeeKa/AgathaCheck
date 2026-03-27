import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/pet.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';
import '../../../vet/domain/entities/vet.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../organization/presentation/providers/organization_providers.dart';

class PetFormController extends StateNotifier<PetFormState> {
  final Ref ref;
  PetFormController(this.ref) : super(PetFormState());

  void populateForm(Pet pet) {
    state = state.copyWith(
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
        state = state.copyWith(photoBase64: base64Encode(bytes));
      }
    } catch (e) {
      // Handle error in UI
    }
  }

  Future<void> pickNeuteredDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.neuteredDate ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) {
      state = state.copyWith(neuteredDate: picked, neuterDismissed: false);
    }
  }

  // Add more methods for savePet, confirmDeletePet, confirmPassedAway, etc.
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
  final int? selectedOrgId;

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
    int? selectedOrgId,
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
