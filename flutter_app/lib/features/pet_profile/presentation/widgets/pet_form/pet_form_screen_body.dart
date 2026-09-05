import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet.dart';
import '../../controllers/pet_form_controller.dart';
import '../../screens/widgets/pet_form_identity_header.dart';
import '../pet_detail/pet_form_preview_card.dart';
import 'pet_form_actions_bar.dart';
import 'pet_form_breakpoints.dart';
import 'pet_form_content.dart';

/// Responsive body for the add/edit pet form screen.
class PetFormScreenBody extends StatelessWidget {
  const PetFormScreenBody({
    super.key,
    required this.formKey,
    required this.controller,
    required this.previewPet,
    required this.previewWeightLabel,
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
  final String? previewWeightLabel;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = PetFormBreakpoints.layoutForWidth(constraints.maxWidth);
        return switch (layout) {
          PetFormLayoutSize.phone => _PhoneLayout(
            key: const Key('pet_form_layout_phone'),
            props: this,
            layoutSize: layout,
          ),
          PetFormLayoutSize.tablet => _TabletLayout(
            key: const Key('pet_form_layout_tablet'),
            props: this,
            layoutSize: layout,
          ),
          PetFormLayoutSize.desktop => _DesktopLayout(
            key: const Key('pet_form_layout_desktop'),
            props: this,
            layoutSize: layout,
          ),
        };
      },
    );
  }

  Widget _actionsBar() {
    return PetFormActionsBar(
      isEditing: isEditing,
      isLoading: isLoading,
      isDirty: controller.isDirty,
      onSave: onSave,
      onCancel: onCancel,
    );
  }

  PetFormContent _formContent({
    required PetFormLayoutSize layoutSize,
    required bool includeActionsBar,
  }) {
    return PetFormContent(
      formKey: formKey,
      controller: controller,
      layoutSize: layoutSize,
      isEditing: isEditing,
      isLoading: isLoading,
      isShared: isShared,
      passedAway: passedAway,
      showWeightInput: showWeightInput,
      initialOrgId: initialOrgId,
      nameController: nameController,
      breedController: breedController,
      weightController: weightController,
      newWeightController: newWeightController,
      bioController: bioController,
      insuranceController: insuranceController,
      chipIdController: chipIdController,
      selectedVetId: selectedVetId,
      neuteredDate: neuteredDate,
      isNeutered: isNeutered,
      onMarkDirty: onMarkDirty,
      onShowWeightInput: onShowWeightInput,
      onHideWeightInput: onHideWeightInput,
      onNeuteredChanged: onNeuteredChanged,
      onPickNeuteredDate: onPickNeuteredDate,
      onClearNeuteredDate: onClearNeuteredDate,
      onVetSelected: onVetSelected,
      onOwnershipChanged: onOwnershipChanged,
      onDelete: onDelete,
      onPassedAway: onPassedAway,
      includeActionsBar: includeActionsBar,
      actionsBar: _actionsBar(),
    );
  }
}

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({
    super.key,
    required this.props,
    required this.layoutSize,
  });

  final PetFormScreenBody props;
  final PetFormLayoutSize layoutSize;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: PetFormIdentityHeader(
              pet: props.previewPet,
              onChangePhoto: props.onChangePhoto,
            ),
          ),
          const SizedBox(height: 24),
          props._formContent(layoutSize: layoutSize, includeActionsBar: false),
        ],
      ),
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
    super.key,
    required this.props,
    required this.layoutSize,
  });

  final PetFormScreenBody props;
  final PetFormLayoutSize layoutSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: PetFormBreakpoints.tabletContentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: PetFormIdentityHeader(
                  pet: props.previewPet,
                  onChangePhoto: props.onChangePhoto,
                ),
              ),
              const SizedBox(height: 24),
              props._formContent(
                layoutSize: layoutSize,
                includeActionsBar: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    super.key,
    required this.props,
    required this.layoutSize,
  });

  final PetFormScreenBody props;
  final PetFormLayoutSize layoutSize;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: PetFormBreakpoints.desktopPageMaxWidth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PetFormPreviewCard(
                  pet: props.previewPet,
                  displayName: props.nameController.text,
                  weightLabel: props.previewWeightLabel,
                ),
              ),
              const SizedBox(width: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: PetFormBreakpoints.desktopFormMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const Key('pet_change_photo_button'),
                        onPressed: props.onChangePhoto,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(l.petFormChangePhoto),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                    ),
                    props._formContent(
                      layoutSize: layoutSize,
                      includeActionsBar: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
