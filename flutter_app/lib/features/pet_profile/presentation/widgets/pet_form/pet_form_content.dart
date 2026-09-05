import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../controllers/pet_form_controller.dart';
import '../../screens/widgets/pet_dob_section.dart';
import '../../screens/widgets/pet_gender_section.dart';
import '../../screens/widgets/pet_ownership_selector.dart';
import '../../screens/widgets/pet_species_section.dart';
import 'pet_form_bio_section.dart';
import 'pet_form_breakpoints.dart';
import 'pet_form_chip_section.dart';
import 'pet_form_edit_actions.dart';
import 'pet_form_insurance_section.dart';
import 'pet_form_labeled_field.dart';
import 'pet_form_neutered_section.dart';
import 'pet_form_section.dart';
import 'pet_form_vet_section.dart';
import 'pet_form_weight_section.dart';

/// Shared form fields for add/edit pet — layout-aware row grouping for tablet+.
class PetFormContent extends StatelessWidget {
  const PetFormContent({
    super.key,
    required this.formKey,
    required this.controller,
    required this.layoutSize,
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
    required this.onMarkDirty,
    required this.onShowWeightInput,
    required this.onHideWeightInput,
    required this.onNeuteredChanged,
    required this.onPickNeuteredDate,
    required this.onClearNeuteredDate,
    required this.onVetSelected,
    required this.onOwnershipChanged,
    required this.onDelete,
    required this.onPassedAway,
    required this.includeActionsBar,
    required this.actionsBar,
  });

  final GlobalKey<FormState> formKey;
  final PetFormController controller;
  final PetFormLayoutSize layoutSize;
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
  final VoidCallback onMarkDirty;
  final VoidCallback onShowWeightInput;
  final VoidCallback onHideWeightInput;
  final ValueChanged<bool?> onNeuteredChanged;
  final VoidCallback onPickNeuteredDate;
  final VoidCallback onClearNeuteredDate;
  final ValueChanged<String?> onVetSelected;
  final ValueChanged<String?> onOwnershipChanged;
  final VoidCallback onDelete;
  final VoidCallback onPassedAway;
  final bool includeActionsBar;
  final Widget actionsBar;

  bool get _usePairedRows => layoutSize != PetFormLayoutSize.phone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            children: _basicDetailsChildren(context, l),
          ),
          const SizedBox(height: 16),
          PetFormSection(
            title: l.petFormHealthDetails,
            children: _healthDetailsChildren(context),
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
                  controller.state = controller.state.copyWith(insurance: value);
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
          if (includeActionsBar) ...[
            const SizedBox(height: 24),
            actionsBar,
          ],
          if (isEditing && !isShared)
            PetFormEditActions(
              isLoading: isLoading,
              passedAway: passedAway,
              onDelete: onDelete,
              onPassedAway: onPassedAway,
            ),
        ],
      ),
    );
  }

  List<Widget> _basicDetailsChildren(BuildContext context, AppLocalizations l) {
    final nameField = PetFormLabeledField(
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
    );

    final speciesField = PetSpeciesSection(
      selectedSpecies: controller.state.selectedSpecies,
      onChanged: (value) {
        controller.state = controller.state.copyWith(selectedSpecies: value);
        onMarkDirty();
      },
    );

    final breedField = PetFormLabeledField(
      label: l.breed,
      child: TextFormField(
        key: const Key('pet_breed_field'),
        controller: breedController,
        decoration: const InputDecoration(),
        onChanged: (value) {
          controller.state = controller.state.copyWith(breed: value);
          onMarkDirty();
        },
      ),
    );

    final genderField = PetGenderSection(
      selectedGender: controller.state.selectedGender,
      onChanged: (value) {
        controller.state = controller.state.copyWith(selectedGender: value);
        onMarkDirty();
      },
    );

    final dobField = PetDobSection(
      dateOfBirth: controller.state.dateOfBirth,
      onChanged: (date) {
        controller.state = controller.state.copyWith(dateOfBirth: date);
        onMarkDirty();
      },
    );

    final weightField = PetFormWeightSection(
      isEditing: isEditing,
      showWeightInput: showWeightInput,
      weightController: weightController,
      newWeightController: newWeightController,
      controller: controller,
      onShowWeightInput: onShowWeightInput,
      onHideWeightInput: onHideWeightInput,
    );

    if (!_usePairedRows) {
      return [
        nameField,
        const SizedBox(height: 16),
        speciesField,
        const SizedBox(height: 16),
        breedField,
        const SizedBox(height: 16),
        genderField,
        const SizedBox(height: 16),
        dobField,
      ];
    }

    return [
      nameField,
      const SizedBox(height: 16),
      Row(
        key: const Key('pet_form_species_breed_row'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: speciesField),
          const SizedBox(width: 16),
          Expanded(child: breedField),
        ],
      ),
      const SizedBox(height: 16),
      genderField,
      const SizedBox(height: 16),
      Row(
        key: const Key('pet_form_dob_weight_row'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: dobField),
          const SizedBox(width: 16),
          Expanded(child: weightField),
        ],
      ),
    ];
  }

  List<Widget> _healthDetailsChildren(BuildContext context) {
    final weightField = PetFormWeightSection(
      isEditing: isEditing,
      showWeightInput: showWeightInput,
      weightController: weightController,
      newWeightController: newWeightController,
      controller: controller,
      onShowWeightInput: onShowWeightInput,
      onHideWeightInput: onHideWeightInput,
    );

    final neuteredField = PetFormNeuteredSection(
      species: controller.state.selectedSpecies,
      isNeutered: isNeutered,
      neuteredDate: neuteredDate,
      onNeuteredChanged: onNeuteredChanged,
      onPickNeuteredDate: onPickNeuteredDate,
      onClearNeuteredDate: onClearNeuteredDate,
    );

    if (!_usePairedRows) {
      return [
        weightField,
        const SizedBox(height: 16),
        neuteredField,
      ];
    }

    return [neuteredField];
  }
}
