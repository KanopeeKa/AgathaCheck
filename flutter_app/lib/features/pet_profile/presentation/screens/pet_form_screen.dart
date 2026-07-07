import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/pet_form_controller.dart';
import '../controllers/pet_form_outcomes.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_form/pet_form_edit_actions.dart';
import '../widgets/pet_form/pet_form_info_tooltip.dart';
import '../widgets/pet_form/pet_form_neutered_section.dart';
import '../widgets/pet_form/pet_form_vet_section.dart';
import '../widgets/pet_form/pet_form_weight_section.dart';
import 'widgets/pet_photo_section.dart';
import 'widgets/pet_species_section.dart';
import 'widgets/pet_gender_section.dart';
import 'widgets/pet_dob_section.dart';
import 'widgets/pet_ownership_selector.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.petId, this.initialOrgId});

  final String? petId;
  final String? initialOrgId;

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PetFormController _controller;

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _newWeightController = TextEditingController();
  final _bioController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _chipIdController = TextEditingController();
  final _assignmentNotesController = TextEditingController();

  String _selectedSpecies = '';
  String? _photoBase64;
  String? _selectedOrgId;
  String? _selectedVetId;
  DateTime? _dateOfBirth;
  DateTime? _neuteredDate;
  bool? _isNeutered;
  bool _passedAway = false;
  bool _isShared = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _showWeightInput = false;

  bool get _isEditing => widget.petId != null;

  @override
  void initState() {
    super.initState();
    _controller = PetFormController();
    if (!_isEditing && widget.initialOrgId != null) {
      _selectedOrgId = widget.initialOrgId;
      _controller.setSelectedOrgId(widget.initialOrgId);
    }
  }

  void _onOwnershipChanged(String? orgId) {
    setState(() => _selectedOrgId = orgId);
    _controller.setSelectedOrgId(orgId);
  }

  void _navigateAfterForm() {
    if (widget.initialOrgId != null) {
      context.go('/organizations/${widget.initialOrgId}');
      return;
    }
    if (_selectedOrgId != null) {
      context.go('/organizations/$_selectedOrgId');
      return;
    }
    context.go('/');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _newWeightController.dispose();
    _bioController.dispose();
    _insuranceController.dispose();
    _chipIdController.dispose();
    _assignmentNotesController.dispose();
    super.dispose();
  }

  void _populateForm(Pet pet) {
    _nameController.text = pet.name;
    _breedController.text = pet.breed;
    _weightController.text = pet.weight?.toString() ?? '';
    _bioController.text = pet.bio;
    _insuranceController.text = pet.insurance;
    _chipIdController.text = pet.chipId;
    _selectedSpecies = pet.species;
    _photoBase64 = pet.photoPath;
    _selectedVetId = pet.vetId;
    _dateOfBirth = pet.dateOfBirth;
    _neuteredDate = pet.neuteredDate;
    _isNeutered = pet.neuteredDate != null ? true : null;
    _passedAway = pet.passedAway;
    _isShared = pet.isShared;
    _selectedOrgId = pet.organizationId;

    _controller.populateForm(pet);
  }

  Future<void> _pickImage() async {
    await _controller.pickImage();
    setState(() {
      _photoBase64 = _controller.state.photoBase64;
    });
  }

  Future<void> _pickNeuteredDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _neuteredDate ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) {
      final date = calendarDateOnly(picked);
      setState(() {
        _neuteredDate = date;
      });
      _controller.state = _controller.state.copyWith(
        neuteredDate: date,
        neuterDismissed: false,
      );
    }
  }

  Future<void> _confirmDeletePet() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deletePet),
        content: Text(l.deletePetConfirm('')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && widget.petId != null) {
      setState(() => _isLoading = true);
      try {
        await ref.read(petListProvider.notifier).deletePet(widget.petId!);
        if (mounted) context.go('/');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete pet: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmPassedAway() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.passedAway),
        content: const Text(
          'Are you sure you want to mark this pet as passed away?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.ok),
          ),
        ],
      ),
    );
    if (confirmed == true && widget.petId != null) {
      setState(() => _isLoading = true);
      try {
        await ref.read(petListProvider.notifier).markPassedAway(widget.petId!);
        if (mounted) context.go('/');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update pet: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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
            PetFormSubmitValidation.invalidWeight => 'Invalid weight',
            PetFormSubmitValidation.petNotFound => 'Pet not found',
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        case PetFormSubmitError(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save pet: $error')),
          );
        case PetFormSubmitSuccess():
          _navigateAfterForm();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    if (_isEditing && !_isInitialized) {
      final petAsync = ref.watch(petByIdProvider(widget.petId!));
      return petAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: AppLogoTitle(title: l.editPetTitle)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: AppLogoTitle(title: l.editPetTitle)),
          body: Center(child: Text('Error: $e')),
        ),
        data: (pet) {
          if (pet != null && !_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _populateForm(pet);
                _isInitialized = true;
              });
            });
          }
          return _buildForm(theme);
        },
      );
    }

    return _buildForm(theme);
  }

  Widget _buildForm(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: _isEditing ? l.editPetTitle : l.addPetTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
          onPressed: _navigateAfterForm,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PetPhotoSection(
                photoBase64: _photoBase64,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 24),
              if (!_isEditing)
                PetOwnershipSelector(
                  controller: _controller,
                  initialOrgId: widget.initialOrgId,
                  selectedOrgId: _selectedOrgId,
                  onOrgIdChanged: _onOwnershipChanged,
                ),
              if (!_isEditing) const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_name_field'),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l.petName,
                  helperText: 'Your pet\'s name or nickname',
                  suffixIcon: PetFormInfoTooltip(
                    message: 'The name your pet responds to',
                  ),
                ),
                onChanged: (value) =>
                    _controller.state = _controller.state.copyWith(name: value),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l.petNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PetSpeciesSection(
                selectedSpecies: _controller.state.selectedSpecies,
                onChanged: (value) {
                  _controller.state = _controller.state.copyWith(
                    selectedSpecies: value,
                  );
                  setState(() => _selectedSpecies = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_breed_field'),
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: l.breed,
                  helperText: 'Breed or variety, if known',
                ),
                onChanged: (value) => _controller.state = _controller.state
                    .copyWith(breed: value),
              ),
              const SizedBox(height: 16),
              PetGenderSection(
                selectedGender: _controller.state.selectedGender,
                onChanged: (value) {
                  _controller.state = _controller.state.copyWith(
                    selectedGender: value,
                  );
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              PetDobSection(
                dateOfBirth: _controller.state.dateOfBirth ?? _dateOfBirth,
                onChanged: (date) {
                  _controller.state = _controller.state.copyWith(
                    dateOfBirth: date,
                  );
                  setState(() => _dateOfBirth = date);
                },
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                PetFormWeightSection(
                  isEditing: true,
                  showWeightInput: _showWeightInput,
                  weightController: _weightController,
                  newWeightController: _newWeightController,
                  controller: _controller,
                  onShowWeightInput: () {
                    setState(() => _showWeightInput = true);
                    _controller.setShowWeightInput(true);
                  },
                  onHideWeightInput: () {
                    setState(() {
                      _showWeightInput = false;
                      _newWeightController.clear();
                    });
                    _controller.setShowWeightInput(false);
                    _controller.setNewWeight('');
                  },
                ),
              if (!_isEditing)
                PetFormWeightSection(
                  isEditing: false,
                  showWeightInput: _showWeightInput,
                  weightController: _weightController,
                  newWeightController: _newWeightController,
                  controller: _controller,
                  onShowWeightInput: () {
                    setState(() => _showWeightInput = true);
                    _controller.setShowWeightInput(true);
                  },
                  onHideWeightInput: () {
                    setState(() {
                      _showWeightInput = false;
                      _newWeightController.clear();
                    });
                    _controller.setShowWeightInput(false);
                    _controller.setNewWeight('');
                  },
                ),
              const SizedBox(height: 16),
              if (!AppConstants.speciesWithoutNeutering.contains(
                _selectedSpecies,
              ))
                PetFormNeuteredSection(
                  isNeutered: _isNeutered,
                  neuteredDate: _neuteredDate,
                  onNeuteredChanged: (val) {
                    setState(() {
                      _isNeutered = val;
                      if (val == false) _neuteredDate = null;
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
                    }
                  },
                  onPickNeuteredDate: _pickNeuteredDate,
                  onClearNeuteredDate: () {
                    setState(() => _neuteredDate = null);
                    _controller.state =
                        _controller.state.copyWith(neuteredDate: null);
                  },
                ),
              if (!AppConstants.speciesWithoutNeutering.contains(
                _selectedSpecies,
              ))
                const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_bio_field'),
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: l.petBio,
                  alignLabelWithHint: true,
                  helperText: 'Personality traits, likes, quirks',
                  suffixIcon: PetFormInfoTooltip(
                    message: 'Anything a caregiver should know about your pet\'s temperament or habits',
                  ),
                ),
                maxLines: 4,
                maxLength: 500,
                onChanged: (value) =>
                    _controller.state = _controller.state.copyWith(bio: value),
              ),
              const SizedBox(height: 16),
              PetFormVetSection(
                selectedVetId: _selectedVetId,
                controller: _controller,
                onVetSelected: (value) => setState(() => _selectedVetId = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_insurance_field'),
                controller: _insuranceController,
                decoration: InputDecoration(
                  labelText: l.insuranceDetails,
                  alignLabelWithHint: true,
                  helperText: 'Policy info for emergencies or vet visits',
                  suffixIcon: PetFormInfoTooltip(
                    message: 'Include details someone else would need to use your pet\'s insurance:\n\n'
                        '\u2022 Insurance company name\n'
                        '\u2022 Policy or contract number\n'
                        '\u2022 Policyholder name (if different from you)\n'
                        '\u2022 Coverage type (accident only, illness, wellness)\n'
                        '\u2022 Excess/deductible amount\n'
                        '\u2022 Emergency helpline number\n\n'
                        'This is especially useful if a pet-sitter or family member needs to take your pet to the vet and claim on your behalf.',
                  ),
                ),
                maxLines: 4,
                maxLength: 500,
                onChanged: (value) => _controller.state = _controller.state
                    .copyWith(insurance: value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_chip_id_field'),
                controller: _chipIdController,
                decoration: InputDecoration(
                  labelText: l.idMicrochip,
                  helperText: 'Identification number for your pet',
                  suffixIcon: PetFormInfoTooltip(
                    message: 'Enter the identification number relevant to your pet:\n\n'
                        '\u2022 Dogs & Cats: microchip number (usually 15 digits), often required by law\n'
                        '\u2022 Horses & Ponies: passport or microchip number\n'
                        '\u2022 Ferrets & Rabbits: microchip number if implanted\n'
                        '\u2022 Birds: leg ring or band number\n'
                        '\u2022 Fish: tank or habitat label\n'
                        '\u2022 Other pets: any ID tag or registration number\n\n'
                        'This is essential if your pet is lost or needs emergency vet care. '
                        'The number is usually found on adoption papers, vet records, or the registration database.',
                  ),
                ),
                onChanged: (value) => _controller.state = _controller.state
                    .copyWith(chipId: value),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('save_pet_button'),
                onPressed: _isLoading ? null : _savePet,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEditing ? 'Update Pet' : l.savePet),
              ),
              if (_isEditing && !_isShared)
                PetFormEditActions(
                  isLoading: _isLoading,
                  passedAway: _passedAway,
                  onDelete: _confirmDeletePet,
                  onPassedAway: _confirmPassedAway,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
