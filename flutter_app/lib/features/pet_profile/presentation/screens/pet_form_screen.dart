import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/constants.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

/// Form screen for adding or editing a pet profile.
///
/// When [petId] is provided, the form loads existing pet data
/// for editing. Otherwise, it creates a new pet profile.
class PetFormScreen extends ConsumerStatefulWidget {
  /// Creates a [PetFormScreen].
  ///
  /// Pass [petId] to edit an existing pet, or leave null to add new.
  const PetFormScreen({super.key, this.petId});

  /// The ID of the pet to edit, or null to add a new pet.
  final String? petId;

  /// Creates the mutable state for this widget.
  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedSpecies = AppConstants.species.first;
  String? _photoBase64;
  String? _selectedVetId;
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get _isEditing => widget.petId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _populateForm(Pet pet) {
    _nameController.text = pet.name;
    _breedController.text = pet.breed;
    _ageController.text = pet.age?.toString() ?? '';
    _weightController.text = pet.weight?.toString() ?? '';
    _bioController.text = pet.bio;
    _selectedSpecies = pet.species;
    _photoBase64 = pet.photoPath;
    _selectedVetId = pet.vetId;
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

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final age = _ageController.text.isNotEmpty
          ? double.tryParse(_ageController.text)
          : null;
      final weight = _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null;

      if (_isEditing) {
        final pet = Pet(
          id: widget.petId!,
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: _breedController.text.trim(),
          age: age,
          weight: weight,
          bio: _bioController.text.trim(),
          photoPath: _photoBase64,
          vetId: _selectedVetId,
        );
        await ref.read(petListProvider.notifier).updatePet(pet);
      } else {
        await ref.read(petListProvider.notifier).addPet(
              name: _nameController.text.trim(),
              species: _selectedSpecies,
              breed: _breedController.text.trim(),
              age: age,
              weight: weight,
              bio: _bioController.text.trim(),
              photoPath: _photoBase64,
              vetId: _selectedVetId,
            );
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.pets),
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
                value: _selectedSpecies,
                decoration: const InputDecoration(
                  labelText: 'Species *',
                  prefixIcon: Icon(Icons.category),
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
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age (years)',
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final num = double.tryParse(value);
                          if (num == null || num < 0) {
                            return 'Invalid age';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(Icons.monitor_weight),
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              _buildVetDropdown(),
              const SizedBox(height: 24),
              FilledButton.icon(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVetDropdown() {
    final vetsAsync = ref.watch(vetListProvider);

    return vetsAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Veterinarian',
          prefixIcon: Icon(Icons.local_hospital),
        ),
        child: Text('Loading vets...'),
      ),
      error: (_, __) => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Veterinarian',
          prefixIcon: Icon(Icons.local_hospital),
        ),
        child: Text('Could not load vets'),
      ),
      data: (vets) {
        return DropdownButtonFormField<String?>(
          value: vets.any((v) => v.id == _selectedVetId) ? _selectedVetId : null,
          decoration: InputDecoration(
            labelText: 'Veterinarian',
            prefixIcon: const Icon(Icons.local_hospital),
            suffixIcon: _selectedVetId != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
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
      child: GestureDetector(
        onTap: _pickImage,
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
                      ),
                    )
                  : Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}
