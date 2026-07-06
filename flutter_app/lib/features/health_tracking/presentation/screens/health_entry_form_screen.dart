import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_issue_providers.dart';
import '../providers/health_providers.dart';
import '../widgets/health_entry_type_labels.dart';
import '../widgets/entry_due_completed_row.dart';
import '../widgets/health_entry_form/health_entry_pet_selector.dart';
import '../widgets/health_entry_form/health_entry_photos_section.dart';

import '../controllers/health_entry_form_constants.dart';
import '../controllers/health_entry_form_controller.dart';
import '../controllers/health_entry_form_outcomes.dart';
import '../widgets/recurrence_anchor_toggle.dart';
import '../widgets/event_history_formatter.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';

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

  HealthEntryFormParams get _params => HealthEntryFormParams(
        entryId: widget.entryId,
        petId: widget.petId,
        initialType: widget.initialType,
        allowedTypes: widget.allowedTypes,
      );

  HealthEntryFormController get _controller =>
      ref.read(healthEntryFormControllerProvider(_params).notifier);

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      Future.microtask(() async {
        try {
          final loaded = await _controller.loadEntry(widget.entryId!);
          if (loaded != null && mounted) {
            _nameController.text = loaded.name;
            _dosageController.text = loaded.dosage;
            _notesController.text = loaded.notes;
          }
          await _controller.loadPhotos();
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
        }
      });
    }
  }

  String _documentValidationMessage(HealthDocumentValidationError error) {
    final l = AppLocalizations.of(context)!;
    return switch (error) {
      HealthDocumentValidationError.unsupportedFormat =>
        l.unsupportedDocumentFormat,
      HealthDocumentValidationError.tooLarge => l.documentTooLarge,
    };
  }

  Future<void> _addPickedDocument(XFile picked, {int? byteLength}) async {
    if (!mounted) return;
    final form = ref.read(healthEntryFormControllerProvider(_params));
    if (form.totalPhotoCount >= healthEntryMaxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.maxPhotosReached)),
      );
      return;
    }

    try {
      final validationError =
          await _controller.addDocument(picked, byteLength: byteLength);
      if (!mounted) return;
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_documentValidationMessage(validationError))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToAddPhoto('$e'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
      if (picked == null) return;
      await _addPickedDocument(picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e'))),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddPhoto('$e'))),
        );
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
      await _controller.deletePhoto(photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToDeletePhoto('$e'))),
        );
      }
    }
  }

  Widget _buildHealthIssueDropdown(HealthEntryFormState form) {
    if (form.selectedPetIds.isEmpty) return const SizedBox.shrink();
    final petId = form.selectedPetIds.first;
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
              value: form.selectedHealthIssueId,
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
              onChanged: (val) => _controller.setSelectedHealthIssueId(val),
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
    final form = ref.watch(healthEntryFormControllerProvider(_params));
    final petListAsync = ref.watch(petListProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: form.isEdit ? l.editEntry : l.addHealthEntry2),
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
      body: form.isLoading
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
                          selectedPetIds: form.selectedPetIds,
                          isEdit: form.isEdit,
                          onChanged: _controller.setSelectedPetIds,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HealthEntryType>(
                      value: form.type,
                      decoration: InputDecoration(
                        labelText: l.entryType,
                      ),
                      items: form.selectableTypes.map((t) {
                        return DropdownMenuItem(
                            value: t, child: Text(_typeLabel(l, t)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _controller.setType(val);
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
                      value: form.frequency,
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
                        if (val != null) _controller.setFrequency(val);
                      },
                    ),
                    if (form.frequency != HealthFrequency.once) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: form.frequencyInterval.clamp(1, 12),
                              decoration: InputDecoration(
                                labelText: l.every,
                              ),
                              items: List.generate(12, (i) => i + 1)
                                  .map((n) => DropdownMenuItem(
                                      value: n, child: Text('$n')))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  _controller.setFrequencyInterval(val);
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
                                _periodLabel(l, form.frequency, form.frequencyInterval),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (form.frequency != HealthFrequency.once) ...[
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.repeatEndsBy,
                        ),
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(l.never),
                              selected: form.repeatEndDate == null,
                              onSelected: (_) =>
                                  _controller.setRepeatEndDate(null),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(form.repeatEndDate != null
                                  ? _formatDate(form.repeatEndDate!)
                                  : l.pickADate),
                              selected: form.repeatEndDate != null,
                              onSelected: (_) async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: form.repeatEndDate ??
                                      DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  _controller.setRepeatEndDate(
                                    calendarDateOnly(picked),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (form.frequency != HealthFrequency.once) ...[
                      const SizedBox(height: 16),
                      RecurrenceAnchorToggle(
                        value: form.recurrenceAnchor,
                        onChanged: _controller.setRecurrenceAnchor,
                      ),
                    ],
                    const SizedBox(height: 16),
                    EntryDueCompletedRow(
                      dueDate: form.dueDate,
                      completedOn: form.completedOn,
                      onDueDateChanged: _controller.setDueDate,
                      onCompletedOnChanged: _controller.setCompletedOn,
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
                                    initialValue: form.remindDaysBefore.toString(),
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
                                        _controller.setRemindDaysBefore(val);
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
                    if (form.selectedPetIds.length == 1)
                      _buildHealthIssueDropdown(form),
                    if (form.selectedPetIds.length == 1)
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
                      photos: form.photos,
                      pendingPhotos: form.pendingPhotos,
                      isUploading: form.isUploadingPhoto,
                      baseUrl: ref.watch(apiBaseUrlProvider),
                      onPickCamera: () => _pickPhoto(ImageSource.camera),
                      onPickGallery: _pickDocument,
                      onDelete: _deletePhoto,
                      onRemovePending: _controller.removePendingPhoto,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('save_health_entry_button'),
                      onPressed: _submit,
                      icon: Icon(form.isEdit ? Icons.save : Icons.add),
                      label: Text(form.isEdit
                          ? l.save
                          : form.selectedPetIds.length > 1
                              ? l.addEntryForPets(form.selectedPetIds.length)
                              : l.addEntry),
                    ),
                    if (form.isEdit) ...[
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
    if (!_formKey.currentState!.validate()) return;

    final text = HealthEntryFormTextValues(
      name: _nameController.text,
      dosage: _dosageController.text,
      notes: _notesController.text,
    );

    var outcome = await _controller.submit(text);
    if (!mounted) return;

    if (outcome is HealthEntrySubmitNeedsMarkCompleted) {
      final prompt = outcome.prompt;
      final l = AppLocalizations.of(context)!;
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.markAsCompletedTitle),
          content: Text(
            prompt.isPast ? l.markCompletedPast : l.markCompletedToday,
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
      outcome = await _controller.submit(
        text,
        markCompleted: result,
        skipMarkCompletedCheck: true,
      );
      if (!mounted) return;
    }

    final l = AppLocalizations.of(context)!;
    switch (outcome) {
      case HealthEntrySubmitValidationFailed(:final reason):
        final message = switch (reason) {
          HealthEntrySubmitValidation.dueOrCompletedRequired =>
            l.dueOrCompletedRequired,
          HealthEntrySubmitValidation.noPetsSelected =>
            l.selectAtLeastOnePet,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      case HealthEntrySubmitError(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorWithMessage('$error'))),
        );
      case HealthEntrySubmitSuccess(:final isEdit, :final petIds):
        for (final petId in petIds) {
          ref.invalidate(petHealthEntriesProvider(petId));
        }
        final count = petIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
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
      case HealthEntrySubmitNeedsMarkCompleted():
        break;
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
}

