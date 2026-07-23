import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';
import '../widgets/health_entry_type_labels.dart';
import '../widgets/entry_due_completed_row.dart';
import '../widgets/health_entry_form/health_entry_document_handler.dart';
import '../widgets/health_entry_form/health_entry_edit_actions.dart';
import '../widgets/health_entry_form/health_entry_frequency_section.dart';
import '../widgets/health_entry_form/health_entry_health_issue_dropdown.dart';
import '../widgets/health_entry_form/health_entry_pet_selector.dart';
import '../widgets/health_entry_form/health_entry_photos_section.dart';
import '../widgets/health_entry_form/health_entry_remind_field.dart';
import '../widgets/health_entry_form/health_entry_text_fields.dart';

import '../controllers/health_entry_form_controller.dart';
import '../controllers/health_entry_form_outcomes.dart';
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

  HealthEntryFormParams get _params => HealthEntryFormParams(
    entryId: widget.entryId,
    petId: widget.petId,
    initialType: widget.initialType,
    allowedTypes: widget.allowedTypes,
  );

  HealthEntryFormController get _controller =>
      ref.read(healthEntryFormControllerProvider(_params).notifier);

  HealthEntryDocumentHandler get _documents => HealthEntryDocumentHandler(
    ref: ref,
    context: context,
    controller: _controller,
    entryId: widget.entryId,
    isMounted: () => mounted,
  );

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      Future.microtask(() async {
        try {
          await _controller.loadEntry(widget.entryId!);
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final form = ref.watch(healthEntryFormControllerProvider(_params));
    final petListAsync = ref.watch(petListProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(
          title: form.isEdit ? l.editEntry : l.addHealthEntry2,
        ),
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
                      decoration: InputDecoration(labelText: l.entryType),
                      items: form.selectableTypes.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(healthEntryTypeLabel(l, t)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _controller.setType(val);
                      },
                    ),
                    const SizedBox(height: 16),
                    HealthEntryNameDosageFields(
                      key: ValueKey(
                        'name-dosage-${form.isEdit}-${widget.entryId ?? 'new'}',
                      ),
                      name: form.name,
                      dosage: form.dosage,
                      onNameChanged: _controller.setName,
                      onDosageChanged: _controller.setDosage,
                    ),
                    const SizedBox(height: 16),
                    HealthEntryFrequencySection(
                      frequency: form.frequency,
                      frequencyInterval: form.frequencyInterval,
                      repeatEndDate: form.repeatEndDate,
                      recurrenceAnchor: form.recurrenceAnchor,
                      controller: _controller,
                    ),
                    const SizedBox(height: 16),
                    EntryDueCompletedRow(
                      dueDate: form.dueDate,
                      completedOn: form.completedOn,
                      onDueDateChanged: _controller.setDueDate,
                      onCompletedOnChanged: _controller.setCompletedOn,
                    ),
                    const SizedBox(height: 16),
                    HealthEntryRemindField(
                      remindDaysBefore: form.remindDaysBefore,
                      onChanged: _controller.setRemindDaysBefore,
                    ),
                    const SizedBox(height: 16),
                    if (form.selectedPetIds.length == 1)
                      HealthEntryHealthIssueDropdown(
                        petId: form.selectedPetIds.first,
                        selectedHealthIssueId: form.selectedHealthIssueId,
                        onChanged: _controller.setSelectedHealthIssueId,
                      ),
                    if (form.selectedPetIds.length == 1)
                      const SizedBox(height: 16),
                    HealthEntryNotesField(
                      key: ValueKey(
                        'notes-${form.isEdit}-${widget.entryId ?? 'new'}',
                      ),
                      notes: form.notes,
                      onChanged: _controller.setNotes,
                    ),
                    const SizedBox(height: 24),
                    HealthEntryPhotosSection(
                      photos: form.photos,
                      pendingPhotos: form.pendingPhotos,
                      isUploading: form.isUploadingPhoto,
                      baseUrl: ref.watch(apiBaseUrlProvider),
                      onPickCamera: () =>
                          _documents.pickPhoto(ImageSource.camera),
                      onPickGallery: _documents.pickDocument,
                      onDelete: _documents.deletePhoto,
                      onRemovePending: _controller.removePendingPhoto,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('save_health_entry_button'),
                      onPressed: _submit,
                      icon: Icon(form.isEdit ? Icons.save : Icons.add),
                      label: Text(
                        form.isEdit
                            ? l.save
                            : form.selectedPetIds.length > 1
                            ? l.addEntryForPets(form.selectedPetIds.length)
                            : l.addEntry,
                      ),
                    ),
                    if (form.isEdit)
                      HealthEntryEditActions(
                        onViewHistory: _viewHistory,
                        onDelete: _confirmDelete,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    var outcome = await _controller.submit();
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
        markCompleted: result,
        skipMarkCompletedCheck: true,
      );
      if (!mounted) return;
    }

    final l = AppLocalizations.of(context)!;
    switch (outcome) {
      case HealthEntrySubmitValidationFailed(:final reason):
        final message = switch (reason) {
          HealthEntrySubmitValidation.nameRequired => l.entryNameRequired,
          HealthEntrySubmitValidation.dueOrCompletedRequired =>
            l.dueOrCompletedRequired,
          HealthEntrySubmitValidation.noPetsSelected => l.selectAtLeastOnePet,
        };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      case HealthEntrySubmitError(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$error'))));
      case HealthEntrySubmitSuccess(:final isEdit, :final petIds):
        for (final petId in petIds) {
          ref.invalidate(petHealthEntriesProvider(petId));
        }
        final count = petIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? l.entryUpdated
                  : count > 1
                  ? l.entriesCreated(count)
                  : l.entryCreated,
            ),
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
                          leading: Icon(
                            Icons.check_circle,
                            color: AppColorTokens.success,
                          ),
                          title: Text(
                            formatEventHistoryLine(
                              h,
                              l,
                              dateFormat,
                              dateTimeFormat,
                            ),
                          ),
                          subtitle: h.notes.isNotEmpty ? Text(h.notes) : null,
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToLoadHistory('$e'),
            ),
          ),
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
        content: Text(
          AppLocalizations.of(context)!.deleteEntryNamedConfirm(
            ref.read(healthEntryFormControllerProvider(_params)).name,
          ),
        ),
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
      await ref
          .read(healthEntriesNotifierProvider.notifier)
          .delete(widget.entryId!);
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToDelete('$e')),
          ),
        );
      }
    }
  }
}
