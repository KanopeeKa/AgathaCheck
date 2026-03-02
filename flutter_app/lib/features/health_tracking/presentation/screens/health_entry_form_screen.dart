import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';

class HealthEntryFormScreen extends ConsumerStatefulWidget {
  const HealthEntryFormScreen({super.key, this.entryId, this.petId});

  final String? entryId;
  final String? petId;

  @override
  ConsumerState<HealthEntryFormScreen> createState() =>
      _HealthEntryFormScreenState();
}

class _HealthEntryFormScreenState
    extends ConsumerState<HealthEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _customDaysController = TextEditingController();

  HealthEntryType _type = HealthEntryType.medication;
  HealthFrequency _frequency = HealthFrequency.once;
  DateTime _startDate = DateTime.now();
  DateTime? _nextDueDate;
  DateTime? _repeatEndDate;
  bool _isLoading = false;
  bool _isEdit = false;
  bool _isUploadingPhoto = false;
  List<EventPhoto> _photos = [];

  final Set<String> _selectedPetIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.petId != null && widget.petId!.isNotEmpty) {
      _selectedPetIds.add(widget.petId!);
    }
    if (widget.entryId != null) {
      _isEdit = true;
      _loadEntry();
      _loadPhotos();
    }
  }

  Future<void> _loadPhotos() async {
    if (widget.entryId == null) return;
    try {
      final ds = ref.read(healthDataSourceProvider);
      final photos = await ds.getPhotos(widget.entryId!);
      if (mounted) setState(() => _photos = photos);
    } catch (_) {}
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    if (widget.entryId == null) return;
    if (_photos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 photos per event')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);
      final bytes = await picked.readAsBytes();
      final ds = ref.read(healthDataSourceProvider);
      await ds.uploadPhoto(widget.entryId!, bytes, picked.name);
      await _loadPhotos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _deletePhoto(EventPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.entryId == null) return;
    try {
      final ds = ref.read(healthDataSourceProvider);
      await ds.deletePhoto(widget.entryId!, photo.id);
      await _loadPhotos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $e')),
        );
      }
    }
  }

  Future<void> _loadEntry() async {
    setState(() => _isLoading = true);
    try {
      final entry = await ref
          .read(healthRepositoryProvider)
          .getEntry(widget.entryId!);
      if (entry != null && mounted) {
        setState(() {
          _nameController.text = entry.name;
          _dosageController.text = entry.dosage;
          _notesController.text = entry.notes;
          _type = entry.type;
          _frequency = entry.frequency;
          _startDate = entry.startDate;
          _nextDueDate = entry.nextDueDate;
          _selectedPetIds.clear();
          _selectedPetIds.add(entry.petId);
          _repeatEndDate = entry.repeatEndDate;
          if (entry.frequencyDays != null) {
            _customDaysController.text = entry.frequencyDays.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load entry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);
    final theme = Theme.of(context);
    final primaryPetId = _selectedPetIds.isNotEmpty ? _selectedPetIds.first : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Entry' : 'New Health Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.petId != null && widget.petId!.isNotEmpty) {
              context.go('/pet/${widget.petId}');
            } else {
              context.go('/health');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    petListAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Failed to load pets: $e'),
                      data: (pets) {
                        if (pets.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'No pets found. Please add a pet first.',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          );
                        }
                        return _PetSelector(
                          pets: pets,
                          selectedPetIds: _selectedPetIds,
                          isEdit: _isEdit,
                          onChanged: (ids) => setState(() {
                            _selectedPetIds.clear();
                            _selectedPetIds.addAll(ids);
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HealthEntryType>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: HealthEntryType.values.map((t) {
                        return DropdownMenuItem(
                            value: t, child: Text(t.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g., Heartgard, Rabies Vaccine',
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty
                              ? 'Name is required'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage / Amount',
                        hintText: 'e.g., 1 tablet, 0.5ml',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HealthFrequency>(
                      value: _frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: HealthFrequency.values.map((f) {
                        return DropdownMenuItem(
                            value: f, child: Text(f.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _frequency = val);
                      },
                    ),
                    if (_frequency == HealthFrequency.custom) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Interval (days)',
                          hintText: 'e.g., 14',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (_frequency == HealthFrequency.custom) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter number of days';
                            }
                            final n = int.tryParse(val.trim());
                            if (n == null || n < 1) {
                              return 'Enter a valid number of days';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                    if (_frequency != HealthFrequency.once) ...[
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Repeat ends by',
                          prefixIcon: Icon(Icons.event_busy),
                        ),
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Never'),
                              selected: _repeatEndDate == null,
                              onSelected: (_) =>
                                  setState(() => _repeatEndDate = null),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(_repeatEndDate != null
                                  ? _formatDate(_repeatEndDate!)
                                  : 'Pick a date'),
                              selected: _repeatEndDate != null,
                              onSelected: (_) async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _repeatEndDate ??
                                      DateTime.now()
                                          .add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _repeatEndDate = picked);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _DatePickerField(
                      label: 'Start Date',
                      date: _startDate,
                      onChanged: (d) => setState(() => _startDate = d),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Additional information...',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 24),
                      _PhotosSection(
                        photos: _photos,
                        isUploading: _isUploadingPhoto,
                        baseUrl: ref.watch(apiBaseUrlProvider),
                        onPickCamera: () =>
                            _pickAndUploadPhoto(ImageSource.camera),
                        onPickGallery: () =>
                            _pickAndUploadPhoto(ImageSource.gallery),
                        onDelete: _deletePhoto,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(_isEdit ? Icons.save : Icons.add),
                      label: Text(_isEdit
                          ? 'Save Changes'
                          : _selectedPetIds.length > 1
                              ? 'Add Entry for ${_selectedPetIds.length} Pets'
                              : 'Add Entry'),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _viewHistory,
                        icon: const Icon(Icons.history),
                        label: const Text('View History'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pet')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(healthEntriesNotifierProvider.notifier);

      final effectiveRepeatEndDate =
          _frequency == HealthFrequency.once ? null : _repeatEndDate;

      if (_isEdit) {
        final entry = HealthEntry(
          id: widget.entryId ?? '',
          petId: _selectedPetIds.first,
          name: _nameController.text.trim(),
          type: _type,
          dosage: _dosageController.text.trim(),
          frequency: _frequency,
          frequencyDays: _frequency == HealthFrequency.custom
              ? int.tryParse(_customDaysController.text.trim())
              : null,
          repeatEndDate: effectiveRepeatEndDate,
          startDate: _startDate,
          nextDueDate: _nextDueDate ?? _startDate,
          notes: _notesController.text.trim(),
        );
        await notifier.updateEntry(entry);
        if (mounted) {
          ref.invalidate(petHealthEntriesProvider(_selectedPetIds.first));
        }
      } else {
        for (final petId in _selectedPetIds) {
          final entry = HealthEntry(
            id: '',
            petId: petId,
            name: _nameController.text.trim(),
            type: _type,
            dosage: _dosageController.text.trim(),
            frequency: _frequency,
            frequencyDays: _frequency == HealthFrequency.custom
                ? int.tryParse(_customDaysController.text.trim())
                : null,
            repeatEndDate: effectiveRepeatEndDate,
            startDate: _startDate,
            nextDueDate: _startDate,
            notes: _notesController.text.trim(),
          );
          await notifier.create(entry);
        }
        if (mounted) {
          for (final petId in _selectedPetIds) {
            ref.invalidate(petHealthEntriesProvider(petId));
          }
        }
      }

      if (mounted) {
        final count = _selectedPetIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Entry updated'
                : count > 1
                    ? '$count entries created'
                    : 'Entry created'),
          ),
        );
        if (widget.petId != null && widget.petId!.isNotEmpty) {
          context.go('/pet/${widget.petId}');
        } else {
          context.go('/health');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewHistory() async {
    if (widget.entryId == null) return;

    try {
      final history = await ref
          .read(healthRepositoryProvider)
          .getHistory(widget.entryId!);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Administration History'),
          content: SizedBox(
            width: double.maxFinite,
            child: history.isEmpty
                ? const Text('No history yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (_, i) {
                      final h = history[i];
                      return ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green),
                        title: Text(_formatDateTime(h.takenAt)),
                        subtitle: h.notes.isNotEmpty
                            ? Text(h.notes)
                            : null,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _PetSelector extends StatelessWidget {
  const _PetSelector({
    required this.pets,
    required this.selectedPetIds,
    required this.isEdit,
    required this.onChanged,
  });

  final List<Pet> pets;
  final Set<String> selectedPetIds;
  final bool isEdit;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isEdit) {
      final pet = pets.where((p) => selectedPetIds.contains(p.id)).firstOrNull;
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Pet',
          prefixIcon: Icon(Icons.pets),
        ),
        child: Text(pet?.name ?? 'Unknown pet'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Pets',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (selectedPetIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'At least one pet must be selected',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (pets.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'Select multiple pets to create an entry for each',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pets.map((pet) {
            final isSelected = selectedPetIds.contains(pet.id);
            return FilterChip(
              avatar: isSelected
                  ? null
                  : CircleAvatar(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
              label: Text(pet.name),
              selected: isSelected,
              onSelected: (selected) {
                final newSet = Set<String>.from(selectedPetIds);
                if (selected) {
                  newSet.add(pet.id);
                } else {
                  newSet.remove(pet.id);
                }
                onChanged(newSet);
              },
            );
          }).toList(),
        ),
        if (pets.length > 1) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => onChanged(pets.map((p) => p.id).toSet()),
                icon: const Icon(Icons.select_all, size: 18),
                label: const Text('Select All'),
              ),
              TextButton.icon(
                onPressed: () => onChanged({}),
                icon: const Icon(Icons.deselect, size: 18),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(DateTime(picked.year, picked.month, picked.day,
              date.hour, date.minute));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.photos,
    required this.isUploading,
    required this.baseUrl,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onDelete,
  });

  final List<EventPhoto> photos;
  final bool isUploading;
  final String baseUrl;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final ValueChanged<EventPhoto> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text('Photos',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (photos.length < 4)
              PopupMenuButton<String>(
                icon: Icon(Icons.add_a_photo,
                    size: 20, color: colorScheme.primary),
                tooltip: 'Add Photo',
                onSelected: (value) {
                  if (value == 'camera') {
                    onPickCamera();
                  } else {
                    onPickGallery();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'camera',
                      child: ListTile(
                        leading: Icon(Icons.camera_alt),
                        title: Text('Camera'),
                        contentPadding: EdgeInsets.zero,
                      )),
                  const PopupMenuItem(
                      value: 'gallery',
                      child: ListTile(
                        leading: Icon(Icons.photo_library),
                        title: Text('Gallery / Files'),
                        contentPadding: EdgeInsets.zero,
                      )),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isUploading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (photos.isEmpty && !isUploading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.add_photo_alternate,
                    size: 36, color: colorScheme.outline),
                const SizedBox(height: 8),
                Text('No photos yet',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Tap + to add photos (max 4)',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.outline)),
              ],
            ),
          ),
        if (photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              final imageUrl = '$baseUrl/${photo.photoPath}';
              return GestureDetector(
                onTap: () => _showFullScreen(context, imageUrl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.broken_image,
                              color: colorScheme.outline),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onDelete(photo),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${photos.length}/4 photos',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.outline)),
          ),
      ],
    );
  }

  void _showFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
