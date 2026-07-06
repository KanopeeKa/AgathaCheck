import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_issue_providers.dart';
import '../providers/health_providers.dart';
import '../widgets/health_entry_type_labels.dart';
import '../widgets/entry_due_completed_row.dart';
import '../widgets/health_entry_form/health_entry_pet_selector.dart';
import '../widgets/health_entry_form/health_entry_photos_section.dart';

import '../widgets/recurrence_anchor_toggle.dart';
import '../widgets/event_history_formatter.dart';
import '../../domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';

const healthDocumentMaxBytes = 2 * 1024 * 1024;
const healthDocumentAllowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

class HealthEntryFormScreen extends ConsumerStatefulWidget {
  const HealthEntryFormScreen({
    super.key,
    this.entryId,
    this.petId,
    this.initialType,
    this.allowedTypes,
  });

  final String? entryId;
  final String? petId;
  final HealthEntryType? initialType;
  /// When set, restricts the type dropdown (e.g. pet profile health events).
  final List<HealthEntryType>? allowedTypes;

  @override
  ConsumerState<HealthEntryFormScreen> createState() =>
      _HealthEntryFormScreenState();
}


class _HealthEntryFormScreenState extends ConsumerState<HealthEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  HealthEntryType _type = HealthEntryType.medication;
  HealthFrequency _frequency = HealthFrequency.once;
  int _frequencyInterval = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  DateTime? _completedOn;
  DateTime? _nextDueDate;
  RecurrenceAnchor _recurrenceAnchor = RecurrenceAnchor.fromCompletion;
  DateTime? _repeatEndDate;
  bool _isEdit = false;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  List<EventPhoto> _photos = [];
  List<XFile> _pendingPhotos = [];
  int _remindDaysBefore = 1;
  String? _selectedHealthIssueId;
  Set<String> _selectedPetIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _type = widget.initialType!;
    } else if (widget.allowedTypes != null && widget.allowedTypes!.isNotEmpty) {
      _type = widget.allowedTypes!.first;
    }
    if (widget.petId != null && widget.petId!.isNotEmpty) {
      _selectedPetIds.add(widget.petId!);
    }
    if (widget.entryId != null) {
      _isEdit = true;
      _loadEntry();
      _loadPhotos();
    }
  }

  int get _totalPhotoCount => _photos.length + _pendingPhotos.length;

  Future<void> _loadPhotos() async {
    if (widget.entryId == null) return;
    try {
      final ds = ref.read(healthDataSourceProvider);
      final photos = await ds.getPhotos(widget.entryId!);
      if (mounted) setState(() => _photos = photos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoadPhotos('$e'))),
        );
      }
    }
  }

  String? _documentValidationError(String filename, int byteLength) {
    final l = AppLocalizations.of(context)!;
    final extension = filename.split('.').last.toLowerCase();
    if (!healthDocumentAllowedExtensions.contains(extension)) {
      return l.unsupportedDocumentFormat;
    }
    if (byteLength > healthDocumentMaxBytes) {
      return l.documentTooLarge;
    }
    return null;
  }

  Future<void> _addPickedDocument(XFile picked, {int? byteLength}) async {
    final length = byteLength ?? await picked.length();
    if (!mounted) return;
    final validationError = _documentValidationError(picked.name, length);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    if (_isEdit) {
      setState(() => _isUploadingPhoto = true);
      final bytes = await picked.readAsBytes();
      final ds = ref.read(healthDataSourceProvider);
      await ds.uploadPhoto(widget.entryId!, bytes, picked.name);
      await _loadPhotos();
      if (mounted) setState(() => _isUploadingPhoto = false);
    } else {
      setState(() => _pendingPhotos.add(picked));
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_totalPhotoCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.maxPhotosReached)),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
      if (picked == null) return;

      await _addPickedDocument(picked);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e'))),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    if (_totalPhotoCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.maxPhotosReached)),
      );
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: healthDocumentAllowedExtensions,
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) return;
      if (!mounted) return;
      if (file.path == null && file.bytes == null) {
        throw Exception(AppLocalizations.of(context)!.failedToPickImage);
      }

      final picked = file.path != null
          ? XFile(file.path!, name: file.name)
          : XFile.fromData(file.bytes!, name: file.name);
      await _addPickedDocument(picked, byteLength: file.size);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e'))),
        );
      }
    }
  }

  void _removePendingPhoto(int index) {
    setState(() => _pendingPhotos.removeAt(index));
  }

  Future<void> _uploadPendingPhotos(String entryId) async {
    if (_pendingPhotos.isEmpty) return;
    final ds = ref.read(healthDataSourceProvider);
    final filesToUpload = List<XFile>.from(_pendingPhotos);
    for (final file in filesToUpload) {
      try {
        final bytes = await file.readAsBytes();
        await ds.uploadPhoto(entryId, bytes, file.name);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToUploadPhotoNamed(file.name, '$e'))),
          );
        }
      }
    }
  }

  Future<void> _deletePhoto(EventPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePhotoTitle),
        content: Text(AppLocalizations.of(context)!.deletePhotoConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(AppLocalizations.of(context)!.delete),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToDeletePhoto('$e'))),
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
          _frequency = entry.frequency == HealthFrequency.custom
              ? HealthFrequency.daily
              : entry.frequency;
          _frequencyInterval = entry.frequency == HealthFrequency.custom
              ? (entry.frequencyDays ?? 1)
              : entry.frequencyInterval;
          _startDate = entry.startDate;
          _dueDate = entry.nextDueDate;
          _completedOn = entry.completedOn;
          _nextDueDate = entry.nextDueDate;
          _recurrenceAnchor = entry.recurrenceAnchor;
          _selectedPetIds.clear();
          _selectedPetIds.add(entry.petId);
          _repeatEndDate = entry.repeatEndDate;
          _remindDaysBefore = entry.remindDaysBefore;
          _selectedHealthIssueId = entry.healthIssueId;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoadEntry('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildHealthIssueDropdown() {
    if (_selectedPetIds.isEmpty) return const SizedBox.shrink();
    final petId = _selectedPetIds.first;
    final issuesAsync = ref.watch(healthIssueNotifierProvider(petId));
    final theme = Theme.of(context);

    return issuesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (issues) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String?>(
              key: const Key('health_issue_dropdown'),
              value: _selectedHealthIssueId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.healthIssueOptional,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(AppLocalizations.of(context)!.none),
                ),
                ...issues.map((issue) => DropdownMenuItem<String?>(
                      value: issue.id,
                      child: Text(issue.title),
                    )),
              ],
              onChanged: (val) => setState(() => _selectedHealthIssueId = val),
            ),
            if (issues.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  AppLocalizations.of(context)!.createHealthIssuesHint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<HealthEntryType> get _selectableTypes {
    if (widget.allowedTypes != null && widget.allowedTypes!.isNotEmpty) {
      return widget.allowedTypes!;
    }
    return HealthEntryType.values;
  }

  String _typeLabel(AppLocalizations l, HealthEntryType t) =>
      healthEntryTypeLabel(l, t);

  String _freqLabel(AppLocalizations l, HealthFrequency f) {
    switch (f) {
      case HealthFrequency.once:
        return l.doesNotRepeat;
      case HealthFrequency.daily:
        return l.daily;
      case HealthFrequency.weekly:
        return l.weekly;
      case HealthFrequency.monthly:
        return l.monthly;
      case HealthFrequency.yearly:
        return l.yearly;
      case HealthFrequency.custom:
        return l.custom;
    }
  }

  String _periodLabel(AppLocalizations l, HealthFrequency f, int interval) {
    final plural = interval != 1;
    switch (f) {
      case HealthFrequency.daily:
        return plural ? l.periodDays : l.daily;
      case HealthFrequency.weekly:
        return plural ? l.periodWeeks : l.weekly;
      case HealthFrequency.monthly:
        return plural ? l.periodMonths : l.monthly;
      case HealthFrequency.yearly:
        return plural ? l.periodYears : l.yearly;
      case HealthFrequency.once:
      case HealthFrequency.custom:
        return _freqLabel(l, f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final petListAsync = ref.watch(petListProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: _isEdit ? l.editEntry : l.addHealthEntry2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
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
                      error: (e, _) => Text(l.failedToLoadPets('$e')),
                      data: (pets) {
                        if (pets.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l.noPetsFoundAddFirst,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          );
                        }
                        return HealthEntryPetSelector(
                          pets: pets,
                          selectedPetIds: _selectedPetIds,
                          isEdit: _isEdit,
                          onChanged: (ids) => setState(() {
                            _selectedPetIds = ids;
                            _selectedHealthIssueId = null;
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HealthEntryType>(
                      value: _type,
                      decoration: InputDecoration(
                        labelText: l.entryType,
                      ),
                      items: _selectableTypes.map((t) {
                        return DropdownMenuItem(
                            value: t, child: Text(_typeLabel(l, t)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('health_name_field'),
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l.entryName,
                        hintText: l.entryNameHint,
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty
                              ? l.entryNameRequired
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('health_dosage_field'),
                      controller: _dosageController,
                      decoration: InputDecoration(
                        labelText: l.dosage,
                        hintText: l.dosageHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HealthFrequency>(
                      value: _frequency,
                      decoration: InputDecoration(
                        labelText: l.frequency,
                      ),
                      items: HealthFrequency.values
                          .where((f) => f != HealthFrequency.custom)
                          .map((f) {
                        return DropdownMenuItem(
                            value: f, child: Text(_freqLabel(l, f)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _frequency = val);
                      },
                    ),
                    if (_frequency != HealthFrequency.once) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _frequencyInterval.clamp(1, 12),
                              decoration: InputDecoration(
                                labelText: l.every,
                              ),
                              items: List.generate(12, (i) => i + 1)
                                  .map((n) => DropdownMenuItem(
                                      value: n, child: Text('$n')))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _frequencyInterval = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l.period,
                              ),
                              child: Text(
                                _periodLabel(l, _frequency, _frequencyInterval),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_frequency != HealthFrequency.once) ...[
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.repeatEndsBy,
                        ),
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(l.never),
                              selected: _repeatEndDate == null,
                              onSelected: (_) =>
                                  setState(() => _repeatEndDate = null),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(_repeatEndDate != null
                                  ? _formatDate(_repeatEndDate!)
                                  : l.pickADate),
                              selected: _repeatEndDate != null,
                              onSelected: (_) async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _repeatEndDate ??
                                      DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _repeatEndDate = calendarDateOnly(picked));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_frequency != HealthFrequency.once) ...[
                      const SizedBox(height: 16),
                      RecurrenceAnchorToggle(
                        value: _recurrenceAnchor,
                        onChanged: (v) => setState(() => _recurrenceAnchor = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                    EntryDueCompletedRow(
                      dueDate: _dueDate,
                      completedOn: _completedOn,
                      onDueDateChanged: (d) => setState(() {
                        _dueDate = d;
                        _nextDueDate = d;
                        if (d != null) _startDate = d;
                      }),
                      onCompletedOnChanged: (d) =>
                          setState(() => _completedOn = d),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l.remindBefore,
                              prefixIcon: const Icon(Icons.notifications_active, size: 20),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    key: const Key('remind_days_field'),
                                    initialValue: _remindDaysBefore.toString(),
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (v) {
                                      final val = int.tryParse(v);
                                      if (val != null && val >= 0) {
                                        setState(() => _remindDaysBefore = val);
                                      }
                                    },
                                  ),
                                ),
                                Text(
                                  l.daysBefore,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedPetIds.length == 1)
                      _buildHealthIssueDropdown(),
                    if (_selectedPetIds.length == 1)
                      const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('health_notes_field'),
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l.notes,
                        hintText: l.notesHint,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    HealthEntryPhotosSection(
                      photos: _photos,
                      pendingPhotos: _pendingPhotos,
                      isUploading: _isUploadingPhoto,
                      baseUrl: ref.watch(apiBaseUrlProvider),
                      onPickCamera: () => _pickPhoto(ImageSource.camera),
                      onPickGallery: _pickDocument,
                      onDelete: _deletePhoto,
                      onRemovePending: _removePendingPhoto,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('save_health_entry_button'),
                      onPressed: _submit,
                      icon: Icon(_isEdit ? Icons.save : Icons.add),
                      label: Text(_isEdit
                          ? l.save
                          : _selectedPetIds.length > 1
                              ? l.addEntryForPets(_selectedPetIds.length)
                              : l.addEntry),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _viewHistory,
                        icon: const Icon(Icons.history),
                        label: Text(l.administrationHistory),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('delete_health_entry_button'),
                        onPressed: _confirmDelete,
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
                        ),
                        label: Text(l.deleteEntry),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (_dueDate == null && _completedOn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.dueOrCompletedRequired)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectAtLeastOnePet)),
      );
      return;
    }

    bool markCompleted = false;
    final today = DateTime.now();
    final dueOnly = _dueDate != null ? calendarDateOnly(_dueDate!) : null;
    final todayOnly = calendarDateOnly(today);

    if (!_isEdit &&
        _frequency == HealthFrequency.once &&
        _completedOn == null &&
        dueOnly != null &&
        !dueOnly.isAfter(todayOnly)) {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.markAsCompletedTitle),
          content: Text(
            dueOnly.isBefore(todayOnly)
                ? AppLocalizations.of(context)!.markCompletedPast
                : AppLocalizations.of(context)!.markCompletedToday,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.keepActive),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.markCompletedAction),
            ),
          ],
        ),
      );
      if (result == null) return;
      markCompleted = result;
      if (markCompleted) {
        setState(() => _completedOn = dueOnly ?? todayOnly);
      }
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(healthEntriesNotifierProvider.notifier);

      final effectiveRepeatEndDate =
          _frequency == HealthFrequency.once ? null : _repeatEndDate;

      final effectiveStart = _dueDate ?? _completedOn ?? _startDate;
      final effectiveDue =
          _frequency == HealthFrequency.once && _completedOn != null
              ? null
              : _dueDate;
      final effectiveCompleted = _completedOn;

      if (_isEdit) {
        final entry = HealthEntry(
          id: widget.entryId ?? '',
          petId: _selectedPetIds.first,
          name: _nameController.text.trim(),
          type: _type,
          dosage: _dosageController.text.trim(),
          frequency: _frequency,
          frequencyInterval: _frequency == HealthFrequency.once ? 1 : _frequencyInterval,
          repeatEndDate: effectiveRepeatEndDate,
          startDate: effectiveStart,
          nextDueDate: effectiveDue,
          completedOn: effectiveCompleted,
          recurrenceAnchor: _recurrenceAnchor,
          notes: _notesController.text.trim(),
          healthIssueId: _selectedHealthIssueId,
          remindDaysBefore: _remindDaysBefore,
        );
        await notifier.updateEntry(entry);
        if (mounted) {
          ref.invalidate(petHealthEntriesProvider(_selectedPetIds.first));
        }
      } else {
        final createdEntryIds = <String>[];
        final createUseCase = ref.read(createHealthEntryProvider);
        for (final petId in _selectedPetIds) {
          final entry = HealthEntry(
            id: '',
            petId: petId,
            name: _nameController.text.trim(),
            type: _type,
            dosage: _dosageController.text.trim(),
            frequency: _frequency,
            frequencyInterval: _frequency == HealthFrequency.once ? 1 : _frequencyInterval,
            repeatEndDate: effectiveRepeatEndDate,
            startDate: effectiveStart,
            nextDueDate: markCompleted ? null : (_dueDate ?? effectiveStart),
            completedOn: markCompleted ? (_completedOn ?? effectiveStart) : _completedOn,
            recurrenceAnchor: _recurrenceAnchor,
            notes: _notesController.text.trim(),
            healthIssueId: _selectedHealthIssueId,
            remindDaysBefore: _remindDaysBefore,
          );
          final created = await createUseCase.call(entry);
          createdEntryIds.add(created.id);
        }
        if (_pendingPhotos.isNotEmpty) {
          for (final entryId in createdEntryIds) {
            await _uploadPendingPhotos(entryId);
          }
        }
        await notifier.refresh();
        if (mounted) {
          for (final petId in _selectedPetIds) {
            ref.invalidate(petHealthEntriesProvider(petId));
          }
        }
      }

      if (mounted) {
        final count = _selectedPetIds.length;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? l.entryUpdated
                : count > 1
                    ? l.entriesCreated(count)
                    : l.entryCreated),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage('$e'))),
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
        builder: (ctx) {
          final l = AppLocalizations.of(context)!;
          final dateFormat = DateFormat.yMMMd();
          final dateTimeFormat = DateFormat.yMMMd().add_jm();
          return AlertDialog(
          title: Text(l.administrationHistory),
          content: SizedBox(
            width: double.maxFinite,
            child: history.isEmpty
                ? Text(l.noHistoryYet)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (_, i) {
                      final h = history[i];
                      return ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green),
                        title: Text(formatEventHistoryLine(
                          h, l, dateFormat, dateTimeFormat,
                        )),
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
              child: Text(l.close),
            ),
          ],
        );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoadHistory('$e'))),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.entryId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteEntry),
        content: Text(AppLocalizations.of(context)!.deleteEntryNamedConfirm(_nameController.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(healthEntriesNotifierProvider.notifier).delete(widget.entryId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.entryDeleted)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToDelete('$e'))),
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

