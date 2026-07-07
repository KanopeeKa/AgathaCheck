import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';
import '../widgets/entry_due_completed_row.dart';
import '../widgets/recurrence_anchor_toggle.dart';
import '../../domain/entities/recurrence_anchor.dart';
import '../widgets/entry_document_section.dart';
import '../widgets/entry_frequency_fields.dart';
import '../widgets/entry_remind_before_field.dart';
import '../widgets/health_entry_type_labels.dart';
import '../controllers/health_entry_form_constants.dart';

/// Simplified add/edit form for pet profile Other events (care + misc.).
class OtherEventFormScreen extends ConsumerStatefulWidget {
  const OtherEventFormScreen({
    super.key,
    this.entryId,
    required this.petId,
    this.initialType,
  });

  final String? entryId;
  final String petId;
  final HealthEntryType? initialType;

  @override
  ConsumerState<OtherEventFormScreen> createState() =>
      _OtherEventFormScreenState();
}

class _OtherEventFormScreenState extends ConsumerState<OtherEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  HealthEntryType _type = HealthEntryType.familyEvent;
  HealthFrequency _frequency = HealthFrequency.once;
  int _frequencyInterval = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  DateTime? _completedOn;
  RecurrenceAnchor _recurrenceAnchor = RecurrenceAnchor.fromCompletion;
  DateTime? _repeatEndDate;
  bool _isEdit = false;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  List<EventPhoto> _photos = [];
  List<XFile> _pendingPhotos = [];
  int _remindDaysBefore = 1;

  static const _allowedTypes = kOtherEventTypes;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null &&
        _allowedTypes.contains(widget.initialType)) {
      _type = widget.initialType!;
    }
    if (widget.entryId != null) {
      _isEdit = true;
      _loadEntry();
      _loadPhotos();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    setState(() => _isLoading = true);
    try {
      final entry = await ref
          .read(healthRepositoryProvider)
          .getEntry(widget.entryId!);
      if (entry != null && mounted) {
        if (!_allowedTypes.contains(entry.type)) {
          throw StateError('Entry is not an other event type');
        }
        setState(() {
          _nameController.text = entry.name;
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
          _recurrenceAnchor = entry.recurrenceAnchor;
          _repeatEndDate = entry.repeatEndDate;
          _remindDaysBefore = entry.remindDaysBefore;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToLoadEntry('$e'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPhotos() async {
    if (widget.entryId == null) return;
    try {
      final ds = ref.read(healthDataSourceProvider);
      final photos = await ds.getPhotos(widget.entryId!);
      if (mounted) setState(() => _photos = photos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToLoadPhotos('$e'),
            ),
          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
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

  Future<void> _pickDocument() async {
    if (_photos.length + _pendingPhotos.length >= 4) {
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e')),
          ),
        );
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) await _addPickedDocument(picked);
  }

  Future<void> _uploadPendingPhotos(String entryId) async {
    final ds = ref.read(healthDataSourceProvider);
    for (final file in _pendingPhotos) {
      final bytes = await file.readAsBytes();
      await ds.uploadPhoto(entryId, bytes, file.name);
    }
  }

  Future<void> _deletePhoto(EventPhoto photo) async {
    try {
      final ds = ref.read(healthDataSourceProvider);
      await ds.deletePhoto(widget.entryId!, photo.id);
      await _loadPhotos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToDeletePhoto('$e'),
            ),
          ),
        );
      }
    }
  }

  void _removePendingPhoto(int index) {
    setState(() => _pendingPhotos.removeAt(index));
  }

  Future<void> _submit() async {
    if (_dueDate == null && _completedOn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.dueOrCompletedRequired),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    bool markCompleted = false;
    final today = DateTime.now();
    final dueOnly = _dueDate != null ? calendarDateOnly(_dueDate!) : null;
    final todayOnly = calendarDateOnly(today);

    if (!_isEdit &&
        _frequency == HealthFrequency.once &&
        _completedOn == null &&
        dueOnly != null &&
        !dueOnly.isAfter(todayOnly)) {
      final l = AppLocalizations.of(context)!;
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.markAsCompletedTitle),
          content: Text(
            dueOnly.isBefore(todayOnly)
                ? l.markCompletedPast
                : l.markCompletedToday,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.keepActive),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.markCompletedAction),
            ),
          ],
        ),
      );
      if (result == null) return;
      markCompleted = result;
      if (markCompleted) {
        setState(() => _completedOn = dueOnly);
      }
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(healthEntriesNotifierProvider.notifier);
      final effectiveRepeatEndDate = _frequency == HealthFrequency.once
          ? null
          : _repeatEndDate;
      final effectiveStart = _dueDate ?? _completedOn ?? _startDate;
      final effectiveDue =
          _frequency == HealthFrequency.once && _completedOn != null
          ? null
          : _dueDate;
      final effectiveCompleted = _completedOn;

      if (_isEdit) {
        final entry = HealthEntry(
          id: widget.entryId ?? '',
          petId: widget.petId,
          name: _nameController.text.trim(),
          type: _type,
          frequency: _frequency,
          frequencyInterval: _frequency == HealthFrequency.once
              ? 1
              : _frequencyInterval,
          repeatEndDate: effectiveRepeatEndDate,
          startDate: effectiveStart,
          nextDueDate: effectiveDue,
          completedOn: effectiveCompleted,
          recurrenceAnchor: _recurrenceAnchor,
          notes: _notesController.text.trim(),
          remindDaysBefore: _remindDaysBefore,
        );
        await notifier.updateEntry(entry);
      } else {
        final createUseCase = ref.read(createHealthEntryProvider);
        final entry = HealthEntry(
          id: '',
          petId: widget.petId,
          name: _nameController.text.trim(),
          type: _type,
          frequency: _frequency,
          frequencyInterval: _frequency == HealthFrequency.once
              ? 1
              : _frequencyInterval,
          repeatEndDate: effectiveRepeatEndDate,
          startDate: effectiveStart,
          nextDueDate: markCompleted ? null : (_dueDate ?? effectiveStart),
          completedOn: markCompleted
              ? (_completedOn ?? effectiveStart)
              : _completedOn,
          recurrenceAnchor: _recurrenceAnchor,
          notes: _notesController.text.trim(),
          remindDaysBefore: _remindDaysBefore,
        );
        final created = await createUseCase.call(entry);
        if (_pendingPhotos.isNotEmpty) {
          await _uploadPendingPhotos(created.id);
        }
        await notifier.refresh();
      }

      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? l.entryUpdated : l.entryCreated)),
        );
        context.go('/pet/${widget.petId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorWithMessage('$e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.entryId == null) return;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteEntry),
        content: Text(l.deleteEntryNamedConfirm(_nameController.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(healthEntriesNotifierProvider.notifier)
          .delete(widget.entryId!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.entryDeleted)));
        context.go('/pet/${widget.petId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.failedToDelete('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final baseUrl = ref.watch(apiBaseUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: _isEdit ? l.editEntry : l.addOtherEvent),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
          onPressed: () => context.go('/pet/${widget.petId}'),
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
                    DropdownButtonFormField<HealthEntryType>(
                      value: _type,
                      decoration: InputDecoration(labelText: l.entryType),
                      items: _allowedTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(healthEntryTypeLabel(l, type)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('other_event_name_field'),
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l.entryName,
                        hintText: l.entryNameHint,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? l.entryNameRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    EntryFrequencyFields(
                      frequency: _frequency,
                      frequencyInterval: _frequencyInterval,
                      repeatEndDate: _repeatEndDate,
                      onFrequencyChanged: (f) => setState(() => _frequency = f),
                      onIntervalChanged: (n) =>
                          setState(() => _frequencyInterval = n),
                      onRepeatEndChanged: (d) =>
                          setState(() => _repeatEndDate = d),
                    ),
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
                        if (d != null) _startDate = d;
                      }),
                      onCompletedOnChanged: (d) =>
                          setState(() => _completedOn = d),
                    ),
                    const SizedBox(height: 16),
                    EntryRemindBeforeField(
                      remindDaysBefore: _remindDaysBefore,
                      onChanged: (days) =>
                          setState(() => _remindDaysBefore = days),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('other_event_notes_field'),
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l.notes,
                        hintText: l.notesHint,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    EntryDocumentSection(
                      photos: _photos,
                      pendingPhotos: _pendingPhotos,
                      isUploading: _isUploadingPhoto,
                      baseUrl: baseUrl,
                      onPickCamera: () => _pickPhoto(ImageSource.camera),
                      onPickGallery: _pickDocument,
                      onDelete: _deletePhoto,
                      onRemovePending: _removePendingPhoto,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('save_other_event_button'),
                      onPressed: _submit,
                      icon: Icon(_isEdit ? Icons.save : Icons.add),
                      label: Text(_isEdit ? l.save : l.addOtherEvent),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('delete_other_event_button'),
                        onPressed: _confirmDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.5,
                            ),
                          ),
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
}
