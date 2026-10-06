part of 'pet_form_screen.dart';

extension _PetFormScreenActions on _PetFormScreenState {
void _navigateAfterForm() {
  if (widget.initialOrgId != null) {
    context.go('/organizations/${widget.initialOrgId}');
    return;
  }
  if (_isEditing && widget.petId != null) {
    goToPetDetail(context, widget.petId!);
    return;
  }
  if (_controller.state.selectedOrgId != null) {
    context.go('/organizations/${_controller.state.selectedOrgId}');
    return;
  }
  context.go('/');
}

Future<bool> _confirmDiscard() async {
  if (!_controller.isDirty || !mounted) return true;
  final l = AppLocalizations.of(context)!;
  return confirmDiscardFormChanges(
    context,
    title: l.petFormUnsavedTitle,
    body: l.petFormUnsavedBody,
    discardLabel: l.petFormDiscard,
  );
}

Future<void> _handleBack() async {
  if (!_controller.isDirty) {
    _navigateAfterForm();
    return;
  }
  if (await _confirmDiscard() && mounted) {
    _navigateAfterForm();
  }
}

String _formTitle(AppLocalizations l) {
  if (!_isEditing) return l.addPetTitle;
  final name = _nameController.text.trim();
  if (name.isNotEmpty) return l.editPetNamed(name);
  return l.editPetTitle;
}

Pet _previewPet() {
  final species = _controller.state.selectedSpecies;
  final weightText = _isEditing
      ? _weightController.text.trim()
      : (_showWeightInput ? _newWeightController.text.trim() : '');
  final parsedWeight = double.tryParse(weightText);

  return Pet(
    id: widget.petId ?? 'new',
    name: _nameController.text.trim().isEmpty
        ? ' '
        : _nameController.text.trim(),
    species: species.isEmpty ? 'Dog' : species,
    breed: _breedController.text.trim(),
    dateOfBirth: _controller.state.dateOfBirth,
    weight: parsedWeight,
    gender: _controller.state.selectedGender,
    photoPath: _controller.state.photoBase64,
    colorValue: _controller.state.existingColorValue,
    passedAway: _passedAway,
  );
}

String? _previewWeightLabel() {
  final weightText = _isEditing
      ? _weightController.text.trim()
      : (_showWeightInput ? _newWeightController.text.trim() : '');
  if (weightText.isEmpty) return null;
  final parsed = double.tryParse(weightText);
  if (parsed == null) return null;
  return '${parsed.toStringAsFixed(1)} kg';
}

void _populateForm(Pet pet, {String? primaryVetContactId}) {
  _suppressDirty = true;
  _nameController.text = pet.name;
  _breedController.text = pet.breed;
  _weightController.text = pet.weight?.toString() ?? '';
  _bioController.text = pet.bio;
  _insuranceController.text = pet.insurance;
  _chipIdController.text = pet.chipId;
  _neuteredDate = pet.neuteredDate;
  _isNeutered = pet.neuteredDate != null
      ? true
      : pet.neuterDismissed
      ? false
      : null;
  _passedAway = pet.passedAway;
  _isShared = pet.isShared;

  _controller.populateForm(pet);
  if (primaryVetContactId != null) {
    _controller.state = _controller.state.copyWith(
      selectedPrimaryVetContactId: primaryVetContactId,
    );
  }
  _controller.captureBaseline();
  _suppressDirty = false;
}

Future<void> _pickImage() async {
  final outcome = await _controller.pickImage();
  if (!mounted) return;

  _markDirty();
  final l = AppLocalizations.of(context)!;
  switch (outcome) {
    case PetFormPickImageSuccess():
      break;
    case PetFormPickImageFailed(:final error):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(petFormPickImageErrorMessage(l, error))),
      );
  }
}

Future<void> _pickNeuteredDate() async {
  final now = DateTime.now();
  final picked = await showCalendarDatePicker(
    context: context,
    initialDate: _neuteredDate ?? now,
    firstDate: DateTime(1990),
    lastDate: now,
  );
  if (picked != null) {
    setState(() => _neuteredDate = picked);
    _controller.state = _controller.state.copyWith(
      neuteredDate: picked,
      neuterDismissed: false,
    );
    _markDirty();
  }
}

void _onNeuteredChanged(bool? val) {
  setState(() {
    _isNeutered = val;
    if (val != true) _neuteredDate = null;
  });
  if (val == true) {
    _controller.state = _controller.state.copyWith(
      isNeutered: true,
      neuterDismissed: false,
    );
  } else if (val == false) {
    _controller.state = _controller.state.copyWith(
      isNeutered: false,
      neuteredDate: null,
    );
  } else {
    _controller.state = _controller.state.copyWith(
      isNeutered: null,
      neuteredDate: null,
    );
  }
  _markDirty();
}

Future<void> _confirmDeletePet() async {
  if (widget.petId == null) return;
  await confirmDeletePet(
    context: context,
    ref: ref,
    petId: widget.petId!,
    petName: _nameController.text.trim(),
    onLoadingChanged: (bool loading) {
      if (mounted) setState(() => _isLoading = loading);
    },
  );
}

Future<void> _confirmPassedAway() async {
  if (widget.petId == null) return;
  await confirmPassedAway(
    context: context,
    ref: ref,
    petId: widget.petId!,
    onLoadingChanged: (bool loading) {
      if (mounted) setState(() => _isLoading = loading);
    },
  );
}

Future<void> _savePrimaryVetSlotIfNeeded(String petId) async {
  final selected = _controller.state.selectedPrimaryVetContactId;
  final baseline = _controller.baselinePrimaryVetContactId;
  if (selected == baseline) return;
  final commands = ref.read(peopleCommandsProvider);
  await commands.setPetSlot(
    contactId: selected ?? baseline ?? '',
    petId: petId,
    slotKind: RelationshipKind.primaryVet,
    slotContactId: selected,
  );
}

Future<void> _savePet() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);
  try {
    final outcome = await _controller.submit(
      PetFormSubmitDeps.fromWidgetRef(ref),
      isEditing: _isEditing,
      petId: widget.petId,
    );
    if (!mounted) return;

    final l = AppLocalizations.of(context)!;
    switch (outcome) {
      case PetFormSubmitValidationFailed(:final reason):
        final message = switch (reason) {
          PetFormSubmitValidation.nameRequired => l.petNameRequired,
          PetFormSubmitValidation.invalidWeight => l.petInvalidWeight,
          PetFormSubmitValidation.petNotFound => l.petNotFound,
        };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      case PetFormSubmitError(:final kind):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(petFormSubmitErrorMessage(l, kind))),
        );
      case PetFormSubmitSuccess(:final petId):
        final targetPetId = petId ?? widget.petId;
        if (targetPetId != null) {
          await _savePrimaryVetSlotIfNeeded(targetPetId);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.petFormPetSaved)));
        _navigateAfterForm();
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
}
