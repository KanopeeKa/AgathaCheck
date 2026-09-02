import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/recurrence_anchor.dart';
import '../widgets/entry_due_completed_row.dart';
import '../widgets/recurrence_anchor_toggle.dart';
import '../widgets/entry_document_section.dart';
import '../widgets/entry_frequency_fields.dart';
import '../widgets/entry_remind_before_field.dart';
import '../widgets/health_entry_type_labels.dart';
import '../widgets/other_event_form/other_event_form_actions.dart';
import '../widgets/other_event_form/other_event_photo_handler.dart';

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

  HealthEntryType _type = HealthEntryType.other;
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

  OtherEventPhotoHandler get _photosHandler => OtherEventPhotoHandler(
    ref: ref,
    context: context,
    entryId: widget.entryId,
    isEdit: _isEdit,
    isMounted: () => mounted,
    getPhotos: () => _photos,
    getPendingPhotos: () => _pendingPhotos,
    setPhotos: (p) => setState(() => _photos = p),
    setPendingPhotos: (p) => setState(() => _pendingPhotos = p),
    setUploading: (v) => setState(() => _isUploadingPhoto = v),
  );

  OtherEventFormActions get _actions => OtherEventFormActions(
    ref: ref,
    context: context,
    petId: widget.petId,
    entryId: widget.entryId,
    isMounted: () => mounted,
    uploadPendingPhotos: _photosHandler.uploadPendingPhotos,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null &&
        _allowedTypes.contains(widget.initialType)) {
      _type = widget.initialType!;
    }
    if (widget.entryId != null) {
      _isEdit = true;
      _actions.loadEntry(
        type: _type,
        allowedTypes: _allowedTypes.toList(),
        setLoading: (v) => setState(() => _isLoading = v),
        applyLoaded:
            ({
              required String name,
              required String notes,
              required HealthEntryType type,
              required HealthFrequency frequency,
              required int frequencyInterval,
              required DateTime startDate,
              required DateTime? dueDate,
              required DateTime? completedOn,
              required RecurrenceAnchor recurrenceAnchor,
              required DateTime? repeatEndDate,
              required int remindDaysBefore,
            }) {
              setState(() {
                _nameController.text = name;
                _notesController.text = notes;
                _type = type;
                _frequency = frequency;
                _frequencyInterval = frequencyInterval;
                _startDate = startDate;
                _dueDate = dueDate;
                _completedOn = completedOn;
                _recurrenceAnchor = recurrenceAnchor;
                _repeatEndDate = repeatEndDate;
                _remindDaysBefore = remindDaysBefore;
              });
            },
      );
      _photosHandler.loadPhotos();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() => _actions.submit(
    isEdit: _isEdit,
    formKey: _formKey,
    dueDate: _dueDate,
    completedOn: _completedOn,
    frequency: _frequency,
    frequencyInterval: _frequencyInterval,
    startDate: _startDate,
    repeatEndDate: _repeatEndDate,
    recurrenceAnchor: _recurrenceAnchor,
    remindDaysBefore: _remindDaysBefore,
    type: _type,
    name: _nameController.text,
    notes: _notesController.text,
    pendingPhotos: _pendingPhotos,
    setLoading: (v) => setState(() => _isLoading = v),
    setCompletedOn: (d) => setState(() => _completedOn = d),
  );

  Future<void> _confirmDelete() => _actions.confirmDelete(
    entryName: _nameController.text,
    onDeleted: () => goToPetDetail(context, widget.petId),
  );

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
          onPressed: () => goToPetDetail(context, widget.petId),
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
                      initialValue: _type,
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
                      onPickCamera: () =>
                          _photosHandler.pickPhoto(ImageSource.camera),
                      onPickGallery: _photosHandler.pickDocument,
                      onDelete: _photosHandler.deletePhoto,
                      onRemovePending: _photosHandler.removePendingPhoto,
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
