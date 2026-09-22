import 'package:image_picker/image_picker.dart';

import '../../../pet_profile/domain/services/care_family_write.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';
import 'health_entry_form_controller_base.dart';
import 'health_entry_form_controller_photos.dart';
import 'health_entry_form_outcomes.dart';
import 'health_entry_form_state.dart';

mixin HealthEntryFormSubmitMixin
    on HealthEntryFormControllerBase, HealthEntryFormPhotoMixin {
  Future<HealthEntrySubmitOutcome> submitForm({
    bool markCompleted = false,
    bool skipMarkCompletedCheck = false,
  }) async {
    if (state.name.trim().isEmpty) {
      return HealthEntrySubmitValidationFailed(
        HealthEntrySubmitValidation.nameRequired,
      );
    }
    if (state.isRecordMode) {
      if (state.completedOn == null) {
        return HealthEntrySubmitValidationFailed(
          HealthEntrySubmitValidation.completedOnRequired,
        );
      }
    } else if (state.dueDate == null && state.completedOn == null) {
      return HealthEntrySubmitValidationFailed(
        HealthEntrySubmitValidation.dueOrCompletedRequired,
      );
    }
    if (state.selectedPetIds.isEmpty) {
      return HealthEntrySubmitValidationFailed(
        HealthEntrySubmitValidation.noPetsSelected,
      );
    }
    if (!state.isEdit && state.careFamily == null) {
      markCareFamilyValidationAttempted();
      return HealthEntrySubmitValidationFailed(
        HealthEntrySubmitValidation.careFamilyRequired,
      );
    }

    if (!skipMarkCompletedCheck && !state.isEdit) {
      final prompt = markCompletedPromptIfNeeded();
      if (prompt != null && !markCompleted) {
        return HealthEntrySubmitNeedsMarkCompleted(prompt);
      }
    }

    if (markCompleted) {
      applyMarkCompleted(true);
    }

    state = state.copyWith(isLoading: true);
    final createdEntryIds = <String>[];
    try {
      final notifier = formRef.read(healthEntriesNotifierProvider.notifier);
      final isRecord = state.isRecordMode;
      final effectiveFrequency = isRecord
          ? HealthFrequency.once
          : state.frequency;
      final effectiveRepeatEndDate =
          isRecord || effectiveFrequency == HealthFrequency.once
          ? null
          : state.repeatEndDate;
      final effectiveStart =
          state.dueDate ?? state.completedOn ?? state.startDate;
      final effectiveDue = isRecord
          ? null
          : (effectiveFrequency == HealthFrequency.once &&
                    state.completedOn != null
                ? null
                : state.dueDate);
      final effectiveCompleted = state.completedOn;
      final effectiveRemindDaysBefore = isRecord ? 0 : state.remindDaysBefore;
      final effectiveScheduleTimes = isRecord
          ? null
          : effectiveScheduleTimesForSubmit();
      final careFamily = resolveCareFamilyForWrite(
        frequency: state.frequency,
        type: state.type,
        selected: state.careFamily,
        existing: state.loadedUncategorised ? null : state.careFamily,
        isCreate: !state.isEdit,
      );

      if (state.isEdit) {
        final entry = HealthEntry(
          id: entryId ?? '',
          petId: state.selectedPetIds.first,
          name: state.name.trim(),
          type: state.type,
          dosage: state.dosage.trim(),
          frequency: effectiveFrequency,
          frequencyInterval: effectiveFrequency == HealthFrequency.once
              ? 1
              : state.frequencyInterval,
          repeatEndDate: effectiveRepeatEndDate,
          startDate: effectiveStart,
          nextDueDate: effectiveDue,
          completedOn: effectiveCompleted,
          recurrenceAnchor: state.recurrenceAnchor,
          notes: state.notes.trim(),
          healthIssueId: state.selectedHealthIssueId,
          remindDaysBefore: effectiveRemindDaysBefore,
          scheduleTimes: effectiveScheduleTimes,
          careFamily: careFamily,
          careSetting: state.careSetting,
          carePlanning: state.carePlanning,
          careImportance: state.careImportance,
          importanceOverridden: state.importanceOverridden,
        );
        await notifier.updateEntry(entry);
        if (state.pendingPhotos.isNotEmpty && entryId != null) {
          final filesToUpload = List<XFile>.from(state.pendingPhotos);
          await uploadPendingPhotosToEntry(entryId!, filesToUpload);
          clearPendingPhotos();
          await loadPhotos();
        }
      } else {
        final createUseCase = formRef.read(createHealthEntryProvider);
        for (final petId in state.selectedPetIds) {
          final entry = HealthEntry(
            id: '',
            petId: petId,
            name: state.name.trim(),
            type: state.type,
            dosage: state.dosage.trim(),
            frequency: effectiveFrequency,
            frequencyInterval: effectiveFrequency == HealthFrequency.once
                ? 1
                : state.frequencyInterval,
            repeatEndDate: effectiveRepeatEndDate,
            startDate: effectiveStart,
            nextDueDate: isRecord
                ? null
                : (markCompleted ? null : (state.dueDate ?? effectiveStart)),
            completedOn: isRecord
                ? effectiveCompleted
                : (markCompleted
                      ? (state.completedOn ?? effectiveStart)
                      : state.completedOn),
            recurrenceAnchor: state.recurrenceAnchor,
            notes: state.notes.trim(),
            healthIssueId: state.selectedHealthIssueId,
            remindDaysBefore: effectiveRemindDaysBefore,
            scheduleTimes: effectiveScheduleTimes,
            careFamily: careFamily,
            careSetting: state.careSetting,
            carePlanning: state.carePlanning,
            careImportance: state.careImportance,
            importanceOverridden: state.importanceOverridden,
          );
          final created = await createUseCase.call(entry);
          createdEntryIds.add(created.id);
        }
        if (state.pendingPhotos.isNotEmpty) {
          final filesToUpload = List<XFile>.from(state.pendingPhotos);
          for (final createdId in createdEntryIds) {
            await uploadPendingPhotosToEntry(createdId, filesToUpload);
          }
          clearPendingPhotos();
        }
        await notifier.refresh();
      }

      return HealthEntrySubmitSuccess(
        isEdit: state.isEdit,
        petIds: Set<String>.from(state.selectedPetIds),
        entryIds: state.isEdit
            ? (entryId != null ? [entryId!] : <String>[])
            : createdEntryIds,
        careSetting: state.careSetting,
        carePlanning: state.carePlanning,
        linkedHealthIssueId: state.selectedHealthIssueId,
      );
    } catch (e) {
      return HealthEntrySubmitError(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
