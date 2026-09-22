import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/form/app_form_destructive_button.dart';
import '../../../../../core/widgets/form/app_form_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../care_taxonomy/presentation/widgets/care_classification_section.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../domain/entities/health_entry.dart';
import '../../controllers/health_entry_form_controller.dart';
import '../../controllers/health_entry_form_state.dart';
import '../entry_due_completed_row.dart';
import 'health_entry_document_handler.dart';
import 'health_entry_frequency_section.dart';
import 'health_entry_health_issue_dropdown.dart';
import 'health_entry_pet_selector.dart';
import 'health_entry_photos_section.dart';
import 'health_entry_remind_field.dart';
import 'health_entry_schedule_times_section.dart';
import 'health_entry_text_fields.dart';

/// Sectioned form fields for add/edit health entries.
class HealthEntryFormContent extends ConsumerWidget {
  const HealthEntryFormContent({
    super.key,
    required this.formKey,
    required this.params,
    required this.documents,
    required this.baseUrl,
    required this.includeActionsBar,
    required this.actionsBar,
    this.onDelete,
  });

  final GlobalKey<FormState> formKey;
  final HealthEntryFormParams params;
  final HealthEntryDocumentHandler documents;
  final String baseUrl;
  final bool includeActionsBar;
  final Widget actionsBar;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final form = ref.watch(healthEntryFormControllerProvider(params));
    final controller = ref.read(
      healthEntryFormControllerProvider(params).notifier,
    );
    final petListAsync = ref.watch(petListProvider);
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormSection(
            title: l.healthEntryFormWhatAndWho,
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
                    onChanged: controller.setSelectedPetIds,
                  );
                },
              ),
              const SizedBox(height: 16),
              CareClassificationSection(
                isEdit: form.isEdit,
                careFamily: form.careFamily,
                careSetting: form.careSetting,
                careImportance: form.careImportance,
                careFamilyRequiredError: form.careFamilyRequiredError(l),
                showCareFamilySuggestion: form.showCareFamilySuggestion,
                showCareFamilyPicker: form.showCareFamilyPicker,
                suggestedCareFamily: form.suggestedCareFamilyForType(),
                onCareFamilyChanged: controller.setCareFamily,
                onCareSettingChanged: controller.setCareSetting,
                onCareImportanceChanged: controller.setCareImportance,
                onAcceptSuggestion: controller.acceptCareFamilySuggestion,
                onChooseDifferentSuggestion: controller.revealCareFamilyPicker,
                onDismissSuggestion: controller.dismissCareFamilySuggestion,
              ),
              const SizedBox(height: 16),
              HealthEntryNameDosageFields(
                key: ValueKey(
                  'name-dosage-${form.isEdit}-${params.entryId ?? 'new'}',
                ),
                name: form.name,
                dosage: form.dosage,
                onNameChanged: controller.setName,
                onDosageChanged: controller.setDosage,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: l.healthEntryFormSchedule,
            children: [
              HealthEntryFrequencySection(
                frequency: form.frequency,
                frequencyInterval: form.frequencyInterval,
                repeatEndDate: form.repeatEndDate,
                recurrenceAnchor: form.recurrenceAnchor,
                controller: controller,
              ),
              if (form.frequency != HealthFrequency.once) ...[
                const SizedBox(height: 16),
                HealthEntryScheduleTimesSection(
                  scheduleAtSpecificTimes: form.scheduleAtSpecificTimes,
                  scheduleTimes: form.scheduleTimes,
                  controller: controller,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: l.healthEntryFormDatesReminders,
            children: [
              EntryDueCompletedRow(
                dueDate: form.dueDate,
                completedOn: form.completedOn,
                onDueDateChanged: controller.setDueDate,
                onCompletedOnChanged: controller.setCompletedOn,
              ),
              const SizedBox(height: 16),
              HealthEntryRemindField(
                remindDaysBefore: form.remindDaysBefore,
                onChanged: controller.setRemindDaysBefore,
              ),
              if (form.selectedPetIds.length == 1) ...[
                const SizedBox(height: 16),
                HealthEntryHealthIssueDropdown(
                  petId: form.selectedPetIds.first,
                  selectedHealthIssueId: form.selectedHealthIssueId,
                  onChanged: controller.setSelectedHealthIssueId,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: l.healthEntryFormNotesDocuments,
            children: [
              HealthEntryNotesField(
                key: ValueKey(
                  'notes-${form.isEdit}-${params.entryId ?? 'new'}',
                ),
                notes: form.notes,
                onChanged: controller.setNotes,
              ),
              const SizedBox(height: 16),
              HealthEntryPhotosSection(
                photos: form.photos,
                pendingPhotos: form.pendingPhotos,
                isUploading: form.isUploadingPhoto,
                baseUrl: baseUrl,
                onPickCamera: () => documents.pickPhoto(ImageSource.camera),
                onPickGallery: documents.pickDocument,
                onDelete: documents.deletePhoto,
                onRemovePending: controller.removePendingPhoto,
              ),
            ],
          ),
          if (includeActionsBar) ...[const SizedBox(height: 24), actionsBar],
          if (form.isEdit && onDelete != null) ...[
            const SizedBox(height: 24),
            AppFormDestructiveButton(
              buttonKey: const Key('delete_health_entry_button'),
              label: l.deleteEntry,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
