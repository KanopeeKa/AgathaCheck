import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet.dart';
import '../../controllers/pet_form_controller.dart';
import '../../widgets/pet_form/pet_form_actions_bar.dart';
import '../../widgets/pet_form/pet_form_bio_section.dart';
import '../../widgets/pet_form/pet_form_chip_section.dart';
import '../../widgets/pet_form/pet_form_edit_actions.dart';
import '../../widgets/pet_form/pet_form_insurance_section.dart';
import '../../widgets/pet_form/pet_form_labeled_field.dart';
import '../../widgets/pet_form/pet_form_neutered_section.dart';
import '../../widgets/pet_form/pet_form_section.dart';
import '../../widgets/pet_form/pet_form_vet_section.dart';
import '../../widgets/pet_form/pet_form_weight_section.dart';
import 'pet_dob_section.dart';
import 'pet_form_identity_header.dart';
import 'pet_gender_section.dart';
import 'pet_ownership_selector.dart';
import 'pet_species_section.dart';

class PetFormScreenBody extends StatelessWidget {
  const PetFormScreenBody({
    super.key,
    required this.formKey,
    required this.controller,
    required this.previewPet,
    required this.isEditing,
    required this.isLoading,
    required this.isShared,
    required this.passedAway,
    required this.showWeightInput,
    required this.initialOrgId,
    required this.nameController,
    required this.breedController,
    required this.weightController,
    required this.newWeightController,
    required this.bioController,
    required this.insuranceController,
    required this.chipIdController,
    required this.selectedVetId,
    required this.neuteredDate,
    required this.isNeutered,
    required this.onChangePhoto,
    required this.onOwnershipChanged,
    required this.onMarkDirty,
    required this.onShowWeightInput,
    required this.onHideWeightInput,
    required this.onNeuteredChanged,
    required this.onPickNeuteredDate,
    required this.onClearNeuteredDate,
    required this.onVetSelected,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
    required this.onPassedAway,
  });

  final GlobalKey<FormState> formKey;
  final PetFormController controller;
  final Pet previewPet;
  final bool isEditing;
  final bool isLoading;
  final bool isShared;
  final bool passedAway;
  final bool showWeightInput;
  final String? initialOrgId;
  final TextEditingController nameController;
  final TextEditingController breedController;
  final TextEditingController weightController;
  final TextEditingController newWeightController;
  final TextEditingController bioController;
  final TextEditingController insuranceController;
  final TextEditingController chipIdController;
  final String? selectedVetId;
  final DateTime? neuteredDate;
  final bool? isNeutered;
  final VoidCallback onChangePhoto;
  final ValueChanged<String?> onOwnershipChanged;
  final VoidCallback onMarkDirty;
  final VoidCallback onShowWeightInput;
  final VoidCallback onHideWeightInput;
  final ValueChanged<bool?> onNeuteredChanged;
  final VoidCallback onPickNeuteredDate;
  final VoidCallback onClearNeuteredDate;
  final ValueChanged<String?> onVetSelected;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onPassedAway;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: PetFormIdentityHeader(
                pet: previewPet,
                onChangePhoto: onChangePhoto,
              ),
            ),
            const SizedBox(height: 24),
            if (!isEditing) ...[
              PetOwnershipSelector(
                controller: controller,
                initialOrgId: initialOrgId,
                selectedOrgId: controller.state.selectedOrgId,
                onOrgIdChanged: onOwnershipChanged,
              ),
              const SizedBox(height: 16),
            ],
            PetFormSection(
              title: l.petFormBasicDetails,
              children: [
                PetFormLabeledField(
                  label: l.petName,
                  child: TextFormField(
                    key: const Key('pet_name_field'),
                    controller: nameController,
                    decoration: const InputDecoration(),
                    onChanged: (value) {
                      controller.state = controller.state.copyWith(name: value);
                      onMarkDirty();
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l.petNameRequired;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                PetSpeciesSection(
                  selectedSpecies: controller.state.selectedSpecies,
                  onChanged: (value) {
                    controller.state = controller.state.copyWith(
                      selectedSpecies: value,
                    );
                    onMarkDirty();
                  },
                ),
                const SizedBox(height: 16),
                PetFormLabeledField(
                  label: l.breed,
                  child: TextFormField(
                    key: const Key('pet_breed_field'),
                    controller: breedController,
                    decoration: const InputDecoration(),
                    onChanged: (value) {
                      controller.state = controller.state.copyWith(
                        breed: value,
                      );
                      onMarkDirty();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                PetGenderSection(
                  selectedGender: controller.state.selectedGender,
                  onChanged: (value) {
                    controller.state = controller.state.copyWith(
                      selectedGender: value,
                    );
                    onMarkDirty();
                  },
                ),
                const SizedBox(height: 16),
                PetDobSection(
                  dateOfBirth: controller.state.dateOfBirth,
                  onChanged: (date) {
                    controller.state = controller.state.copyWith(
                      dateOfBirth: date,
                    );
                    onMarkDirty();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            PetFormSection(
              title: l.petFormHealthDetails,
              children: [
                PetFormWeightSection(
                  isEditing: isEditing,
                  showWeightInput: showWeightInput,
                  weightController: weightController,
                  newWeightController: newWeightController,
                  controller: controller,
                  onShowWeightInput: onShowWeightInput,
                  onHideWeightInput: onHideWeightInput,
                ),
                const SizedBox(height: 16),
                PetFormNeuteredSection(
                  species: controller.state.selectedSpecies,
                  isNeutered: isNeutered,
                  neuteredDate: neuteredDate,
                  onNeuteredChanged: onNeuteredChanged,
                  onPickNeuteredDate: onPickNeuteredDate,
                  onClearNeuteredDate: onClearNeuteredDate,
                ),
              ],
            ),
            const SizedBox(height: 16),
            PetFormSection(
              title: l.petFormAbout,
              children: [
                PetFormBioSection(
                  petName: nameController.text,
                  textController: bioController,
                  onChanged: (value) {
                    controller.state = controller.state.copyWith(bio: value);
                    onMarkDirty();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            PetFormSection(
              title: l.petFormCareAndRecords,
              children: [
                PetFormVetSection(
                  selectedVetId: selectedVetId,
                  controller: controller,
                  onVetSelected: onVetSelected,
                ),
                const SizedBox(height: 16),
                PetFormInsuranceSection(
                  textController: insuranceController,
                  onChanged: (value) {
                    controller.state = controller.state.copyWith(
                      insurance: value,
                    );
                    onMarkDirty();
                  },
                ),
                const SizedBox(height: 16),
                PetFormChipSection(
                  textController: chipIdController,
                  onChanged: (value) {
                    controller.state = controller.state.copyWith(chipId: value);
                    onMarkDirty();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            PetFormActionsBar(
              isEditing: isEditing,
              isLoading: isLoading,
              isDirty: controller.isDirty,
              onSave: onSave,
              onCancel: onCancel,
            ),
            if (isEditing && !isShared)
              PetFormEditActions(
                isLoading: isLoading,
                passedAway: passedAway,
                onDelete: onDelete,
                onPassedAway: onPassedAway,
              ),
          ],
        ),
      ),
    );
  }
}
