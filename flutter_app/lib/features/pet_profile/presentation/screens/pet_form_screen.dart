import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../controllers/pet_form_controller.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vet/domain/entities/vet.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';
import 'widgets/pet_photo_section.dart';
import 'widgets/pet_species_section.dart';
import 'widgets/pet_gender_section.dart';
import 'widgets/pet_dob_section.dart';
import 'widgets/pet_ownership_selector.dart';

String _localizedSpecies(AppLocalizations l, String species) {
  switch (species) {
    case 'Dog': return l.speciesDog;
    case 'Cat': return l.speciesCat;
    case 'Bird': return l.speciesBird;
    case 'Fish': return l.speciesFish;
    case 'Rabbit': return l.speciesRabbit;
    case 'Hamster': return l.speciesHamster;
    case 'Ferret': return l.speciesFerret;
    case 'Horse / Poney': return l.speciesHorsePoney;
    case 'Other': return l.speciesOther;
    default: return species;
  }
}

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.petId, this.initialOrgId});

  final String? petId;
  final int? initialOrgId;

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
  String? _selectedGender;
  String? _photoBase64;
  int? _selectedOrgId;
  String? _selectedVetId;
  int? _existingColorValue;
  DateTime? _dateOfBirth;
  DateTime? _neuteredDate;
  bool? _isNeutered;
  bool _neuterDismissed = false;
  bool _chipDismissed = false;
  bool _passedAway = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _showWeightInput = false;

  bool get _isEditing => widget.petId != null;

  @override
  void initState() {
    super.initState();
    _controller = PetFormController();
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
    _selectedGender = pet.gender;
    _photoBase64 = pet.photoPath;
    _selectedVetId = pet.vetId;
    _existingColorValue = pet.colorValue;
    _dateOfBirth = pet.dateOfBirth;
    _neuteredDate = pet.neuteredDate;
    _isNeutered = pet.neuteredDate != null ? true : null;
    _neuterDismissed = pet.neuterDismissed;
    _chipDismissed = pet.chipDismissed;
    _passedAway = pet.passedAway;
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
      setState(() {
        _neuteredDate = picked;
        _neuterDismissed = false;
      });
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete pet: $e')),
          );
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
        content: const Text('Are you sure you want to mark this pet as passed away?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.ok)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update pet: $e')),
          );
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
      final name = _controller.state.name.isNotEmpty ? _controller.state.name : _nameController.text.trim();
      final species = _controller.state.selectedSpecies.isNotEmpty ? _controller.state.selectedSpecies : _selectedSpecies;
      final breed = _controller.state.breed.isNotEmpty ? _controller.state.breed : _breedController.text.trim();
      final bio = _controller.state.bio.isNotEmpty ? _controller.state.bio : _bioController.text.trim();
      final insurance = _controller.state.insurance.isNotEmpty ? _controller.state.insurance : _insuranceController.text.trim();
      final chipId = _controller.state.chipId.isNotEmpty ? _controller.state.chipId : _chipIdController.text.trim();
      final weightStr = _isEditing
          ? (_controller.state.weight.isNotEmpty ? _controller.state.weight : _weightController.text.trim())
          : _newWeightController.text.trim();
      final weight = weightStr.isNotEmpty ? double.tryParse(weightStr) : null;

      if (_isEditing) {
        final pets = ref.read(petListProvider).valueOrNull ?? [];
        final existing = pets.where((p) => p.id == widget.petId).firstOrNull;
        if (existing != null) {
          final updated = existing.copyWith(
            name: name,
            species: species,
            breed: breed,
            dateOfBirth: _dateOfBirth,
            weight: weight,
            gender: _selectedGender,
            bio: bio,
            insurance: insurance,
            neuteredDate: _neuteredDate,
            neuterDismissed: _neuterDismissed,
            chipId: chipId,
            chipDismissed: _chipDismissed,
            photoPath: _photoBase64,
            vetId: _selectedVetId,
            passedAway: _passedAway,
            organizationId: _selectedOrgId,
            clearVetId: _selectedVetId == null,
            clearGender: _selectedGender == null,
            clearNeuteredDate: _neuteredDate == null,
            clearDateOfBirth: _dateOfBirth == null,
          );
          await ref.read(petListProvider.notifier).updatePet(updated);
        }
      } else {
        await ref.read(petListProvider.notifier).addPet(
          name: name,
          species: species,
          breed: breed,
          dateOfBirth: _dateOfBirth,
          weight: weight,
          gender: _selectedGender,
          bio: bio,
          insurance: insurance,
          neuteredDate: _neuteredDate,
          neuterDismissed: _neuterDismissed,
          chipId: chipId,
          chipDismissed: _chipDismissed,
          photoPath: _photoBase64,
          vetId: _selectedVetId,
          organizationId: _selectedOrgId,
        );
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save pet: $e')),
        );
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
          onPressed: () => context.go('/'),
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
              if (!_isEditing) PetOwnershipSelector(controller: _controller, initialOrgId: widget.initialOrgId),
              if (!_isEditing) const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_name_field'),
                initialValue: _controller.state.name,
                decoration: InputDecoration(
                  labelText: l.petName,
                  helperText: 'Your pet\'s name or nickname',
                  suffixIcon: _infoTooltip('The name your pet responds to'),
                ),
                onChanged: (value) => _controller.state = _controller.state.copyWith(name: value),
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
                  _controller.state = _controller.state.copyWith(selectedSpecies: value);
                  setState(() => _selectedSpecies = value ?? '');
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_breed_field'),
                initialValue: _controller.state.breed,
                decoration: InputDecoration(
                  labelText: l.breed,
                  helperText: 'Breed or variety, if known',
                ),
                onChanged: (value) => _controller.state = _controller.state.copyWith(breed: value),
              ),
              const SizedBox(height: 16),
              PetGenderSection(
                selectedGender: _controller.state.selectedGender,
                onChanged: (value) {
                  _controller.state = _controller.state.copyWith(selectedGender: value);
                  setState(() => _selectedGender = value);
                },
              ),
              const SizedBox(height: 16),
              PetDobSection(
                dateOfBirth: _controller.state.dateOfBirth ?? _dateOfBirth,
                onChanged: (date) {
                  _controller.state = _controller.state.copyWith(dateOfBirth: date);
                  setState(() => _dateOfBirth = date);
                },
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                TextFormField(
                  key: const Key('pet_weight_field'),
                  initialValue: _controller.state.weight,
                  decoration: InputDecoration(
                    labelText: l.weightWithUnit('kg'),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _controller.state = _controller.state.copyWith(weight: value),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final num = double.tryParse(value);
                      if (num == null || num < 0) {
                        return 'Invalid weight';
                      }
                    }
                    return null;
                  },
                ),
              if (!_isEditing)
                _showWeightInput
                    ? TextFormField(
                        key: const Key('pet_initial_weight_field'),
                        controller: _newWeightController,
                        decoration: InputDecoration(
                          labelText: l.weightWithUnit('kg'),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Remove weight entry',
                            onPressed: () {
                              setState(() {
                                _showWeightInput = false;
                                _newWeightController.clear();
                              });
                            },
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = double.tryParse(value);
                            if (num == null || num <= 0) {
                              return 'Invalid weight';
                            }
                          }
                          return null;
                        },
                      )
                    : Tooltip(
                        message: 'Add initial weight entry',
                        child: OutlinedButton.icon(
                          key: const Key('add_weight_entry_button'),
                          onPressed: () => setState(() => _showWeightInput = true),
                          icon: const Icon(Icons.monitor_weight_outlined, size: 18),
                          label: Text(l.addWeightEntry),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
              const SizedBox(height: 16),
              if (!AppConstants.speciesWithoutNeutering.contains(_selectedSpecies))
                _buildNeuteredDateField(theme),
              if (!AppConstants.speciesWithoutNeutering.contains(_selectedSpecies))
                const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_bio_field'),
                initialValue: _controller.state.bio,
                decoration: InputDecoration(
                  labelText: l.petBio,
                  alignLabelWithHint: true,
                  helperText: 'Personality traits, likes, quirks',
                  suffixIcon: _infoTooltip('Anything a caregiver should know about your pet\'s temperament or habits'),
                ),
                maxLines: 4,
                maxLength: 500,
                onChanged: (value) => _controller.state = _controller.state.copyWith(bio: value),
              ),
              const SizedBox(height: 16),
              _buildVetDropdown(),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_insurance_field'),
                initialValue: _controller.state.insurance,
                decoration: InputDecoration(
                  labelText: l.insuranceDetails,
                  alignLabelWithHint: true,
                  helperText: 'Policy info for emergencies or vet visits',
                  suffixIcon: _infoTooltip(
                    'Include details someone else would need to use your pet\'s insurance:\n\n'
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
                onChanged: (value) => _controller.state = _controller.state.copyWith(insurance: value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_chip_id_field'),
                initialValue: _controller.state.chipId,
                decoration: InputDecoration(
                  labelText: l.idMicrochip,
                  helperText: 'Identification number for your pet',
                  suffixIcon: _infoTooltip(
                    'Enter the identification number relevant to your pet:\n\n'
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
                onChanged: (value) => _controller.state = _controller.state.copyWith(chipId: value),
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
              if (_isEditing) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('delete_pet_button'),
                  onPressed: _isLoading ? null : _confirmDeletePet,
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  label: Text(
                    l.deletePet,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error.withAlpha(120)),
                  ),
                ),
                if (!_passedAway) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('passed_away_button'),
                    onPressed: _isLoading ? null : _confirmPassedAway,
                    icon: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFF8800),
                          Color(0xFFFFFF00),
                          Color(0xFF00CC00),
                          Color(0xFF0066FF),
                          Color(0xFF8800CC),
                        ],
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: const Icon(Icons.air, size: 20),
                    ),
                    label: Text(l.passedAway),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.outline.withAlpha(80)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTooltip(String message) {
    final l = AppLocalizations.of(context)!;
    return IconButton(
      icon: Icon(Icons.info_outline,
          size: 18, color: Theme.of(context).colorScheme.outline),
      tooltip: message,
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.ok),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNeuteredDateField(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.neuteredSpayedDate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            _infoTooltip(
              'Whether your pet has been surgically sterilised:\n\n'
              '\u2022 Neutered: male animals (castration)\n'
              '\u2022 Spayed: female animals (ovariectomy / ovariohysterectomy)\n\n'
              'This applies to dogs, cats, rabbits, and other mammals. '
              'Recording the date helps your vet track recovery and adjust any health recommendations.\n\n'
              'If your pet is not yet neutered/spayed, selecting "No" will show a reminder on their profile.',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: RadioListTile<bool>(
                key: const Key('pet_neutered_yes'),
                title: const Text('Yes'),
                value: true,
                groupValue: _isNeutered,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _isNeutered = true;
                    _neuterDismissed = false;
                  });
                },
              ),
            ),
            SizedBox(
              width: 120,
              child: RadioListTile<bool>(
                key: const Key('pet_neutered_no'),
                title: const Text('No'),
                value: false,
                groupValue: _isNeutered,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _isNeutered = false;
                    _neuteredDate = null;
                  });
                },
              ),
            ),
          ],
        ),
        if (_isNeutered == true)
          InkWell(
            key: const Key('pet_neutered_date_field'),
            onTap: _pickNeuteredDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l.date,
                suffixIcon: _neuteredDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear date',
                        onPressed: () => setState(() => _neuteredDate = null),
                      )
                    : null,
              ),
              child: Text(
                _neuteredDate != null
                    ? dateFormat.format(_neuteredDate!)
                    : 'Select date (optional)',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _neuteredDate != null
                      ? null
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const _createNewVetSentinel = '__create_new_vet__';

  Widget _buildVetDropdown() {
    final l = AppLocalizations.of(context)!;
    final vetsAsync = ref.watch(vetListProvider);

    return vetsAsync.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(
          labelText: l.veterinarians,
        ),
        child: const Text('Loading vets...'),
      ),
      error: (_, __) => InputDecorator(
        decoration: InputDecoration(
          labelText: l.veterinarians,
        ),
        child: const Text('Could not load vets'),
      ),
      data: (vets) {
        return DropdownButtonFormField<String?>(
          value: vets.any((v) => v.id == _selectedVetId) ? _selectedVetId : null,
          decoration: InputDecoration(
            labelText: l.veterinarians,
            suffixIcon: _selectedVetId != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear veterinarian',
                    onPressed: () => setState(() => _selectedVetId = null),
                  )
                : null,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l.noVetAssigned),
            ),
            ...vets.map((vet) => DropdownMenuItem<String?>(
                  value: vet.id,
                  child: Text(vet.name),
                )),
            DropdownMenuItem<String?>(
              value: _createNewVetSentinel,
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Create new vet',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value == _createNewVetSentinel) {
              _showCreateVetSheet();
            } else {
              setState(() => _selectedVetId = value);
            }
          },
        );
      },
    );
  }

  void _showCreateVetSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New Veterinarian',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('new_vet_name_field'),
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Dr. Smith Veterinary Clinic',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('new_vet_phone_field'),
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('new_vet_email_field'),
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('new_vet_address_field'),
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('save_new_vet_button'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final vet = Vet(
                    id: '',
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    email: emailController.text.trim(),
                    address: addressController.text.trim(),
                  );
                  try {
                    await ref.read(vetListProvider.notifier).createVet(vet);
                    if (ctx.mounted) Navigator.pop(ctx);
                    final updatedVets = await ref.read(vetListProvider.future);
                    if (updatedVets.isNotEmpty) {
                      setState(() {
                        _selectedVetId = updatedVets.last.id;
                      });
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed to create vet: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
