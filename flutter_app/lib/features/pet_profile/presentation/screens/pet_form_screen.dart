import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../organization/domain/entities/organization_member.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../vet/domain/entities/vet.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

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
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _bioController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _chipIdController = TextEditingController();

  String _selectedSpecies = AppConstants.species.first;
  String? _selectedGender;
  String? _photoBase64;
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
  int? _selectedOrgId;
  bool _orgInitialized = false;
  final _newWeightController = TextEditingController();
  int? _assignedToUserId;
  DateTime? _assignmentFromDate;
  DateTime? _assignmentToDate;
  final _assignmentNotesController = TextEditingController();

  bool get _isEditing => widget.petId != null;

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
  }

  Future<void> _pickImage() async {
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
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
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
    final petName = _nameController.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ll = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(ll.deletePet),
          content: Text(ll.deletePetConfirm(petName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ll.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ll.delete),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      await ref.read(petListProvider.notifier).deletePet(widget.petId!);
      if (mounted) context.go('/');
    }
  }

  Future<void> _confirmPassedAway() async {
    final l = AppLocalizations.of(context)!;
    final petName = _nameController.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ll = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.favorite, color: Colors.grey[400], size: 22),
              const SizedBox(width: 8),
              Text(ll.passedAway),
            ],
          ),
          content: Text(ll.passedAwayConfirmMessage(petName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ll.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey[600],
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ll.confirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final hasSharedUsers = await ref
        .read(petListProvider.notifier)
        .markPassedAway(widget.petId!);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final ll = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.favorite, color: Colors.grey[400], size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'In loving memory of $petName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ll.passedAwayCondolence(petName),
                style: theme.textTheme.bodyMedium,
              ),
              if (hasSharedUsers) ...[
                const SizedBox(height: 16),
                Text(
                  'A notification has been sent to everyone who shared $petName\'s profile to let them know of their passing.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'We will remove any further health reminders and notifications. $petName\'s profile will be kept in your archive so you can always look back on their memories.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Thank you'),
            ),
          ],
        );
      },
    );

    if (mounted) context.go('/');
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final weight = _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null;

      if (_isEditing) {
        final pet = Pet(
          id: widget.petId!,
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: _breedController.text.trim(),
          dateOfBirth: _dateOfBirth,
          weight: weight,
          gender: _selectedGender,
          bio: _bioController.text.trim(),
          insurance: _insuranceController.text.trim(),
          neuteredDate: _neuteredDate,
          neuterDismissed: _neuterDismissed,
          chipId: _chipIdController.text.trim(),
          chipDismissed: _chipDismissed,
          photoPath: _photoBase64,
          vetId: _selectedVetId,
          colorValue: _existingColorValue,
          passedAway: _passedAway,
        );
        await ref.read(petListProvider.notifier).updatePet(pet);
      } else {
        final initialWeight = _showWeightInput && _newWeightController.text.isNotEmpty
            ? double.tryParse(_newWeightController.text)
            : null;

        int? effectiveAssignedUserId = _assignedToUserId;
        DateTime? effectiveFromDate = _assignmentFromDate;
        if (_selectedOrgId != null) {
          final isSuperUser = ref.read(isOrgSuperUserProvider(_selectedOrgId!));
          if (!isSuperUser) {
            final authState = ref.read(authProvider);
            effectiveAssignedUserId = int.tryParse(authState.user?.id ?? '');
            effectiveFromDate ??= DateTime.now();
          }
        }

        final newPetId = await ref.read(petListProvider.notifier).addPet(
              name: _nameController.text.trim(),
              species: _selectedSpecies,
              breed: _breedController.text.trim(),
              dateOfBirth: _dateOfBirth,
              weight: initialWeight,
              gender: _selectedGender,
              bio: _bioController.text.trim(),
              insurance: _insuranceController.text.trim(),
              neuteredDate: _neuteredDate,
              neuterDismissed: _neuterDismissed,
              chipId: _chipIdController.text.trim(),
              chipDismissed: _chipDismissed,
              photoPath: _photoBase64,
              vetId: _selectedVetId,
              organizationId: _selectedOrgId,
            );
        if (initialWeight != null) {
          try {
            final repo = ref.read(weightRepositoryProvider);
            await repo.createEntry(WeightEntry(
              id: 0,
              petId: newPetId,
              date: DateTime.now(),
              weight: initialWeight,
              notes: 'Initial weight',
            ));
          } catch (_) {}
        }
        if (_selectedOrgId != null && effectiveAssignedUserId != null && effectiveFromDate != null) {
          try {
            await ref.read(familyEventsProvider(newPetId).notifier).createEvent(
              assignedToUserId: effectiveAssignedUserId,
              fromDate: effectiveFromDate,
              toDate: _assignmentToDate,
              notes: _assignmentNotesController.text.trim(),
            );
          } catch (_) {}
        }
        if (mounted) context.go('/pet/$newPetId');
        return;
      }

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving pet: $e')),
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
          appBar: AppBar(title: Text(l.editPetTitle)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(l.editPetTitle)),
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
        title: Text(_isEditing ? l.editPetTitle : l.addPetTitle),
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
              _buildPhotoSection(theme),
              const SizedBox(height: 24),
              if (!_isEditing) _buildOwnershipSelector(theme, l),
              if (!_isEditing) const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_name_field'),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l.petName,
                  helperText: 'Your pet\'s name or nickname',
                  suffixIcon: _infoTooltip('The name your pet responds to'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l.petNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('pet_species_field'),
                value: _selectedSpecies,
                decoration: InputDecoration(
                  labelText: l.species,
                  helperText: 'Select the type of animal',
                  suffixIcon: _infoTooltip('Choose the species that best matches your pet'),
                ),
                items: AppConstants.species
                    .map((s) => DropdownMenuItem(value: s, child: Text(_localizedSpecies(l, s))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSpecies = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_breed_field'),
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: l.breed,
                  helperText: 'Breed or variety, if known',
                  suffixIcon: _infoTooltip('e.g. Labrador, Siamese, Budgerigar'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: const Key('pet_gender_field'),
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: l.gender,
                  helperText: 'Useful for health and behaviour tracking',
                  suffixIcon: _selectedGender != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear gender',
                          onPressed: () =>
                              setState(() => _selectedGender = null),
                        )
                      : _infoTooltip('Helps vets and caregivers with gender-specific care'),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Not specified'),
                  ),
                  DropdownMenuItem(value: 'Male', child: Text(l.male)),
                  DropdownMenuItem(value: 'Female', child: Text(l.female)),
                ],
                onChanged: (value) =>
                    setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l.dateOfBirth,
                      child: InkWell(
                        key: const Key('pet_dob_field'),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateOfBirth ?? DateTime.now(),
                            firstDate: DateTime(1980),
                            lastDate: DateTime.now(),
                            helpText: 'Select date of birth',
                          );
                          if (picked != null) {
                            setState(() => _dateOfBirth = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l.dateOfBirth,
                            helperText: 'Used to calculate your pet\'s age',
                            suffixIcon: _dateOfBirth != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    tooltip: 'Clear date of birth',
                                    onPressed: () =>
                                        setState(() => _dateOfBirth = null),
                                  )
                                : const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _dateOfBirth != null
                                ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                                : '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_isEditing)
                    Expanded(
                      child: TextFormField(
                        key: const Key('pet_weight_field'),
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: l.weightWithUnit('kg'),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
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
                    )
                  else
                    Expanded(
                      child: _showWeightInput
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
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
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (!AppConstants.speciesWithoutNeutering.contains(_selectedSpecies))
                _buildNeuteredDateField(theme),
              if (!AppConstants.speciesWithoutNeutering.contains(_selectedSpecies))
                const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_bio_field'),
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: l.petBio,
                  alignLabelWithHint: true,
                  helperText: 'Personality traits, likes, quirks',
                  suffixIcon: _infoTooltip('Anything a caregiver should know about your pet\'s temperament or habits'),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              _buildVetDropdown(),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_insurance_field'),
                controller: _insuranceController,
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_chip_id_field'),
                controller: _chipIdController,
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

  Widget _buildOwnershipSelector(ThemeData theme, AppLocalizations l) {
    final orgsAsync = ref.watch(organizationListProvider);
    if (!_orgInitialized) {
      _orgInitialized = true;
      _selectedOrgId = widget.initialOrgId;
    }
    return orgsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (orgs) {
        if (orgs.isEmpty) return const SizedBox.shrink();

        final effectiveOrgId = _selectedOrgId != null && orgs.any((o) => o.id == _selectedOrgId)
            ? _selectedOrgId!
            : (_selectedOrgId != null ? orgs.first.id : null);

        final isSuperUser = effectiveOrgId != null
            ? ref.watch(isOrgSuperUserProvider(effectiveOrgId))
            : false;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.petOwnership,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l.myPet),
                      icon: const Icon(Icons.person, size: 18),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l.orgPet),
                      icon: const Icon(Icons.business, size: 18),
                    ),
                  ],
                  selected: {_selectedOrgId != null},
                  onSelectionChanged: (v) {
                    setState(() {
                      if (v.first) {
                        _selectedOrgId = widget.initialOrgId ?? orgs.first.id;
                      } else {
                        _selectedOrgId = null;
                        _assignedToUserId = null;
                        _assignmentFromDate = null;
                        _assignmentToDate = null;
                        _assignmentNotesController.clear();
                      }
                    });
                  },
                ),
                if (_selectedOrgId != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: const Key('pet_org_selector'),
                    value: effectiveOrgId,
                    decoration: InputDecoration(
                      labelText: l.organizations,
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: orgs.map((o) => DropdownMenuItem(
                      value: o.id,
                      child: Text(o.name),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _selectedOrgId = v;
                      _assignedToUserId = null;
                    }),
                  ),
                  if (isSuperUser && effectiveOrgId != null)
                    _buildAssignmentSection(theme, l, effectiveOrgId),
                  if (!isSuperUser)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l.autoAssignedToYou,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentSection(ThemeData theme, AppLocalizations l, int orgId) {
    final membersAsync = ref.watch(orgMembersProvider(orgId));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l.assignTo,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
        Text(l.assignToHint,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        membersAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (members) {
            final activeMembers = members.where((m) => !m.role.isPending).toList();
            return DropdownButtonFormField<int?>(
              key: const Key('pet_assign_member'),
              value: _assignedToUserId,
              decoration: InputDecoration(
                labelText: l.assignedMember,
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _assignedToUserId != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _assignedToUserId = null),
                      )
                    : null,
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l.notAssigned,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ),
                ...activeMembers.map((m) => DropdownMenuItem<int?>(
                  value: m.userId,
                  child: Text(m.displayName),
                )),
              ],
              onChanged: (v) => setState(() => _assignedToUserId = v),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _assignmentFromDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _assignmentFromDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.fromDateLabel,
                    suffixIcon: _assignmentFromDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _assignmentFromDate = null),
                          )
                        : const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    _assignmentFromDate != null
                        ? dateFormat.format(_assignmentFromDate!)
                        : '',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _assignmentToDate ?? _assignmentFromDate ?? DateTime.now(),
                    firstDate: _assignmentFromDate ?? DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _assignmentToDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '${l.toDateLabel} (${l.optional})',
                    suffixIcon: _assignmentToDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _assignmentToDate = null),
                          )
                        : const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    _assignmentToDate != null
                        ? dateFormat.format(_assignmentToDate!)
                        : '',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _assignmentNotesController,
          decoration: InputDecoration(
            labelText: '${l.notes} (${l.optional})',
            prefixIcon: const Icon(Icons.note_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    return Center(
      child: Semantics(
        label: _photoBase64 != null && _photoBase64!.isNotEmpty
            ? 'Pet photo. Tap to change photo'
            : 'No pet photo. Tap to add photo',
        button: true,
        child: GestureDetector(
          onTap: _pickImage,
          child: Tooltip(
            message: 'Pick pet photo',
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _photoBase64 != null && _photoBase64!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(_photoBase64!),
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            semanticLabel: 'Pet photo',
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppConstants.speciesIconWidget(
                              _selectedSpecies,
                              size: 40,
                              color: theme.colorScheme.primary.withAlpha(180),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.add_a_photo,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                              semanticLabel: 'Add photo',
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to add photo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
