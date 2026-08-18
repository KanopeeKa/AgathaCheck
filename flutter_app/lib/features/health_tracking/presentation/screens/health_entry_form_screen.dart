import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';
import '../widgets/health_entry_type_labels.dart';
import '../widgets/entry_due_completed_row.dart';
import '../widgets/health_entry_form/health_entry_document_handler.dart';
import '../widgets/health_entry_form/health_entry_frequency_section.dart';
import '../widgets/health_entry_form/health_entry_health_issue_dropdown.dart';
import '../widgets/health_entry_form/health_entry_pet_selector.dart';
import '../widgets/health_entry_form/health_entry_photos_section.dart';
import '../widgets/health_entry_form/health_entry_remind_field.dart';
import '../widgets/health_entry_form/health_entry_text_fields.dart';

import '../controllers/health_entry_form_controller.dart';
import '../controllers/health_entry_form_outcomes.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';

/// All pet event types on the unified edit form (W18).
const kAllPetEventTypes = HealthEntryType.values;

/// Redirects legacy `/pet/:petId/health/edit/:id` and `/other/edit/:id` paths.
String? legacyPetEventEditRedirectForPath(String path) {
  final healthMatch = RegExp(
    r'^/pet/([^/]+)/health/edit/([^/]+)$',
  ).firstMatch(path);
  if (healthMatch != null) {
    return '/pet/${healthMatch.group(1)}/events/${healthMatch.group(2)}/edit';
  }
  final otherMatch = RegExp(
    r'^/pet/([^/]+)/other/edit/([^/]+)$',
  ).firstMatch(path);
  if (otherMatch != null) {
    return '/pet/${otherMatch.group(1)}/events/${otherMatch.group(2)}/edit';
  }
  return null;
}

String? redirectLegacyPetEventEditPath(GoRouterState state) =>
    legacyPetEventEditRedirectForPath(state.uri.path);

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
  late final HealthEntryFormParams _params;

  @override
  void initState() {
    super.initState();
    _params = HealthEntryFormParams(
      entryId: widget.entryId,
      petId: widget.petId,
      initialType: widget.initialType,
      allowedTypes: widget.allowedTypes,
    );
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
          onPressed: () => _navigateBack(context, form.isEdit),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          key: const Key('delete_health_entry_button'),
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
      case HealthEntrySubmitValidationFailed():
        // Validation errors are shown in the UI via FormState.validate()
        break;
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
        if (isEdit &&
            widget.entryId != null &&
            widget.petId != null &&
            widget.petId!.isNotEmpty) {
          context.go('/pet/${widget.petId}/events/${widget.entryId}');
        } else if (widget.petId != null && widget.petId!.isNotEmpty) {
          context.go('/pet/${widget.petId}');
        } else {
          context.go('/g/events');
        }
      case HealthEntrySubmitNeedsMarkCompleted():
        break;
    }
  }

  void _navigateBack(BuildContext context, bool isEdit) {
    if (isEdit &&
        widget.entryId != null &&
        widget.petId != null &&
        widget.petId!.isNotEmpty) {
      context.go('/pet/${widget.petId}/events/${widget.entryId}');
    } else if (widget.petId != null && widget.petId!.isNotEmpty) {
      context.go('/pet/${widget.petId}');
    } else {
      context.go('/g/events');
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.entryId == null) return;
    final form = ref.read(healthEntryFormControllerProvider(_params));
    final l = AppLocalizations.of(context)!;
    final isRecurring = form.frequency != HealthFrequency.once;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteEntry),
        content: Text(
          isRecurring
              ? l.deleteRecurringEntryNamedConfirm(form.name)
              : l.deleteEntryNamedConfirm(form.name),
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
          context.go('/g/events');
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
