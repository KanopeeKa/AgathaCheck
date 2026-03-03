import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/constants.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.petId});

  final String? petId;

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
  final _newWeightController = TextEditingController();

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
    final petName = _nameController.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text(
          'Are you sure you want to delete $petName? '
          'This will permanently remove all linked health events, '
          'health issues, weight records, notifications, and '
          'shared access for this pet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(petListProvider.notifier).deletePet(widget.petId!);
      if (mounted) context.go('/');
    }
  }

  Future<void> _confirmPassedAway() async {
    final petName = _nameController.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.grey[400], size: 22),
            const SizedBox(width: 8),
            const Text('Passed Away'),
          ],
        ),
        content: Text(
          'Are you sure you would like to mark $petName as having passed away?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.grey[600],
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
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
                'We are deeply sorry for your loss. $petName has crossed the rainbow bridge, and we know how much they meant to you.',
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

    if (_isEditing && !_isInitialized) {
      final petAsync = ref.watch(petByIdProvider(widget.petId!));
      return petAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Pet')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Pet')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pet' : 'Add Pet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Go back',
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
              TextFormField(
                key: const Key('pet_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the pet\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('pet_species_field'),
                value: _selectedSpecies,
                decoration: const InputDecoration(
                  labelText: 'Species *',
                ),
                items: AppConstants.species
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
                decoration: const InputDecoration(
                  labelText: 'Breed',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: const Key('pet_gender_field'),
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  suffixIcon: _selectedGender != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear gender',
                          onPressed: () =>
                              setState(() => _selectedGender = null),
                        )
                      : null,
                ),
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Not specified'),
                  ),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Date of birth',
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
                            labelText: 'Date of Birth',
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
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
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
                                labelText: 'Weight (kg)',
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
                                label: const Text('Add Weight'),
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
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  alignLabelWithHint: true,
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
                decoration: const InputDecoration(
                  labelText: 'Insurance Details',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('pet_chip_id_field'),
                controller: _chipIdController,
                decoration: const InputDecoration(
                  labelText: 'ID / Microchip Number',
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
                label: Text(_isEditing ? 'Update Pet' : 'Save Pet'),
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
                    'Delete Pet',
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
                    label: const Text('Passed Away'),
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

  Widget _buildNeuteredDateField(ThemeData theme) {
    final dateFormat = DateFormat.yMMMd();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neutered / Spayed',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
                labelText: 'Date',
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

  Widget _buildVetDropdown() {
    final vetsAsync = ref.watch(vetListProvider);

    return vetsAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Veterinarian',
        ),
        child: Text('Loading vets...'),
      ),
      error: (_, __) => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Veterinarian',
        ),
        child: Text('Could not load vets'),
      ),
      data: (vets) {
        return DropdownButtonFormField<String?>(
          value: vets.any((v) => v.id == _selectedVetId) ? _selectedVetId : null,
          decoration: InputDecoration(
            labelText: 'Veterinarian',
            suffixIcon: _selectedVetId != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear veterinarian',
                    onPressed: () => setState(() => _selectedVetId = null),
                  )
                : null,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('No vet assigned'),
            ),
            ...vets.map((vet) => DropdownMenuItem<String?>(
                  value: vet.id,
                  child: Text(vet.name),
                )),
          ],
          onChanged: (value) => setState(() => _selectedVetId = value),
        );
      },
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
