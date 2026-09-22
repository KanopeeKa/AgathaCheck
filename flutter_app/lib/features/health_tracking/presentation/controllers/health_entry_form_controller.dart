import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../care_taxonomy/domain/care_importance.dart';
import '../../../care_taxonomy/domain/care_planning_mode.dart';
import '../../../care_taxonomy/domain/care_setting.dart';
import '../../../care_taxonomy/domain/care_taxonomy.dart';
import '../../../pet_profile/domain/entities/care_family.dart';
import '../../../pet_profile/domain/services/care_family_write.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/recurrence_anchor.dart';
import '../providers/health_providers.dart';
import 'health_entry_form_constants.dart';
import 'health_entry_form_outcomes.dart';
import 'health_entry_form_state.dart';

export 'health_entry_form_state.dart';

class HealthEntryFormController extends StateNotifier<HealthEntryFormState> {
  HealthEntryFormController(this.ref, HealthEntryFormParams params)
    : super(_initialState(params));

  final Ref ref;
  String? _entryId;
  HealthEntryFormState? _baseline;

  bool get isDirty =>
      _baseline != null && !state.matchesEditableFields(_baseline!);

  void captureBaseline() => _baseline = state;

  static HealthEntryFormState _initialState(HealthEntryFormParams params) {
    var type = HealthEntryType.medication;
    if (params.initialType != null) {
      type = params.initialType!;
    } else if (params.allowedTypes != null && params.allowedTypes!.isNotEmpty) {
      type = params.allowedTypes!.first;
    }

    final selectedPetIds = <String>{};
    if (params.petId != null && params.petId!.isNotEmpty) {
      selectedPetIds.add(params.petId!);
    }

    final initialPlanning =
        params.initialPlanningMode ?? CarePlanningMode.planned;
    final isRecord = initialPlanning == CarePlanningMode.unplanned;

    return HealthEntryFormState(
      type: type,
      isEdit: params.entryId != null,
      selectedPetIds: selectedPetIds,
      allowedTypes: params.allowedTypes,
      carePlanning: initialPlanning,
      remindDaysBefore: isRecord ? 0 : 1,
      completedOn: isRecord ? calendarDateOnly(DateTime.now()) : null,
    );
  }

  String? get entryId => _entryId;

  HealthDocumentValidationError? validateDocument(
    String filename,
    int byteLength,
  ) {
    final extension = filename.split('.').last.toLowerCase();
    if (!healthDocumentAllowedExtensions.contains(extension)) {
      return HealthDocumentValidationError.unsupportedFormat;
    }
    if (byteLength > healthDocumentMaxBytes) {
      return HealthDocumentValidationError.tooLarge;
    }
    return null;
  }

  bool canAddPhoto() => state.totalPhotoCount < healthEntryMaxPhotos;

  Future<HealthDocumentValidationError?> addDocument(
    XFile picked, {
    int? byteLength,
  }) async {
    if (!canAddPhoto()) {
      return null;
    }

    final length = byteLength ?? await picked.length();
    final validationError = validateDocument(picked.name, length);
    if (validationError != null) {
      return validationError;
    }

    if (state.isEdit && _entryId != null) {
      state = state.copyWith(isUploadingPhoto: true);
      try {
        final bytes = await picked.readAsBytes();
        final ds = ref.read(healthDataSourceProvider);
        await ds.uploadPhoto(_entryId!, bytes, picked.name);
        await loadPhotos();
      } finally {
        state = state.copyWith(isUploadingPhoto: false);
      }
    } else {
      state = state.copyWith(pendingPhotos: [...state.pendingPhotos, picked]);
    }
    return null;
  }

  void removePendingPhoto(int index) {
    final updated = List<XFile>.from(state.pendingPhotos)..removeAt(index);
    state = state.copyWith(pendingPhotos: updated);
  }

  Future<void> loadPhotos() async {
    if (_entryId == null) return;
    final ds = ref.read(healthDataSourceProvider);
    final photos = await ds.getPhotos(_entryId!);
    state = state.copyWith(photos: photos);
  }

  Future<void> deletePhoto(EventPhoto photo) async {
    if (_entryId == null) return;
    final ds = ref.read(healthDataSourceProvider);
    await ds.deletePhoto(_entryId!, photo.id);
    await loadPhotos();
  }

  Future<void> uploadPendingPhotosToEntry(
    String entryId,
    List<XFile> files,
  ) async {
    if (files.isEmpty) return;
    final ds = ref.read(healthDataSourceProvider);
    for (final file in files) {
      final bytes = await file.readAsBytes();
      await ds.uploadPhoto(entryId, bytes, file.name);
    }
  }

  void clearPendingPhotos() => state = state.copyWith(pendingPhotos: const []);

  Future<bool> loadEntry(String entryId) async {
    _entryId = entryId;
    state = state.copyWith(isLoading: true, isEdit: true);
    try {
      final entry = await ref.read(healthRepositoryProvider).getEntry(entryId);
      if (entry == null) return false;

      final frequency = entry.frequency == HealthFrequency.custom
          ? HealthFrequency.daily
          : entry.frequency;
      final frequencyInterval = entry.frequency == HealthFrequency.custom
          ? (entry.frequencyDays ?? 1)
          : entry.frequencyInterval;

      state = state.copyWith(
        name: entry.name,
        dosage: entry.dosage,
        notes: entry.notes,
        type: entry.type,
        frequency: frequency,
        frequencyInterval: frequencyInterval,
        startDate: entry.startDate,
        dueDate: entry.nextDueDate,
        completedOn: entry.completedOn,
        recurrenceAnchor: entry.recurrenceAnchor,
        repeatEndDate: entry.repeatEndDate,
        remindDaysBefore: entry.remindDaysBefore,
        selectedHealthIssueId: entry.healthIssueId,
        selectedPetIds: {entry.petId},
        scheduleAtSpecificTimes:
            entry.scheduleTimes != null && entry.scheduleTimes!.isNotEmpty,
        scheduleTimes: entry.scheduleTimes?.isNotEmpty == true
            ? List<String>.from(entry.scheduleTimes!)
            : const ['08:00'],
        careFamily: entry.careFamily,
        careSetting:
            entry.careSetting ??
            CareTaxonomy.defaultSettingFor(entry.careFamily),
        carePlanning: entry.carePlanning ?? CarePlanningMode.planned,
        careImportance:
            entry.careImportance ??
            CareTaxonomy.defaultImportanceFor(entry.careFamily),
        importanceOverridden: entry.importanceOverridden,
        loadedUncategorised: entry.careFamily == null,
        careFamilySuggestionDismissed: false,
        careFamilyPickerRevealed: entry.careFamily != null,
      );

      captureBaseline();
      return true;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void setName(String name) => state = state.copyWith(name: name);

  void setDosage(String dosage) => state = state.copyWith(dosage: dosage);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void setType(HealthEntryType type) {
    if (state.isEdit && !state.loadedUncategorised) {
      state = state.copyWith(type: type);
      return;
    }
    state = state.copyWith(
      type: type,
      clearCareFamily: true,
      careSetting: CareTaxonomy.nullFamilyDefaultSetting,
      careImportance: CareTaxonomy.nullFamilyDefaultImportance,
      importanceOverridden: false,
    );
  }

  void setCareFamily(CareFamily family) {
    state = state.copyWith(
      careFamily: family,
      careSetting: CareTaxonomy.defaultSettingFor(family),
      careImportance: CareTaxonomy.defaultImportanceFor(family),
      importanceOverridden: false,
      careFamilyPickerRevealed: true,
      careFamilyValidationAttempted: false,
    );
  }

  void setCareSetting(CareSetting setting) =>
      state = state.copyWith(careSetting: setting);

  void setCarePlanning(CarePlanningMode planning) =>
      state = state.copyWith(carePlanning: planning);

  void setCareImportance(CareImportance importance) {
    final defaultImportance = CareTaxonomy.defaultImportanceFor(state.careFamily);
    state = state.copyWith(
      careImportance: importance,
      importanceOverridden: importance != defaultImportance,
    );
  }

  void setCarePlanning(CarePlanningMode mode) {
    if (state.carePlanning == mode) return;

    if (mode == CarePlanningMode.unplanned) {
      state = state.copyWith(
        carePlanning: mode,
        frequency: HealthFrequency.once,
        clearDueDate: true,
        clearRepeatEndDate: true,
        remindDaysBefore: 0,
        scheduleAtSpecificTimes: false,
        scheduleTimes: const ['08:00'],
        completedOn: state.completedOn ?? calendarDateOnly(DateTime.now()),
      );
      return;
    }

    state = state.copyWith(
      carePlanning: mode,
      remindDaysBefore: state.remindDaysBefore == 0 ? 1 : state.remindDaysBefore,
    );
  }

  void markCareFamilyValidationAttempted() =>
      state = state.copyWith(careFamilyValidationAttempted: true);

  void dismissCareFamilySuggestion() =>
      state = state.copyWith(careFamilySuggestionDismissed: true);

  void acceptCareFamilySuggestion() {
    final family = defaultCareFamilyForEntryType(state.type);
    state = state.copyWith(
      careFamily: family,
      careSetting: CareTaxonomy.defaultSettingFor(family),
      careImportance: CareTaxonomy.defaultImportanceFor(family),
      importanceOverridden: false,
      careFamilyPickerRevealed: true,
      careFamilySuggestionDismissed: true,
    );
  }

  void revealCareFamilyPicker() => state = state.copyWith(
    careFamilyPickerRevealed: true,
    careFamilySuggestionDismissed: true,
  );

  void setFrequency(HealthFrequency frequency) =>
      state = state.copyWith(frequency: frequency);

  void setFrequencyInterval(int interval) =>
      state = state.copyWith(frequencyInterval: interval);

  void setRepeatEndDate(DateTime? date) => state = state.copyWith(
    repeatEndDate: date,
    clearRepeatEndDate: date == null,
  );

  void setRecurrenceAnchor(RecurrenceAnchor anchor) =>
      state = state.copyWith(recurrenceAnchor: anchor);

  void setDueDate(DateTime? date) =>
      state = state.copyWith(dueDate: date, startDate: date ?? state.startDate);

  void setCompletedOn(DateTime? date) => state = state.copyWith(
    completedOn: date,
    clearCompletedOn: date == null,
  );

  void setRemindDaysBefore(int days) =>
      state = state.copyWith(remindDaysBefore: days);

  void setSelectedHealthIssueId(String? id) => state = state.copyWith(
    selectedHealthIssueId: id,
    clearHealthIssueId: id == null,
  );

  void setSelectedPetIds(Set<String> ids) =>
      state = state.copyWith(selectedPetIds: ids, clearHealthIssueId: true);

  void setScheduleAtSpecificTimes(bool value) {
    state = state.copyWith(
      scheduleAtSpecificTimes: value,
      scheduleTimes: value && state.scheduleTimes.isEmpty
          ? const ['08:00']
          : state.scheduleTimes,
    );
  }

  void setScheduleTime(int index, String time) {
    final updated = List<String>.from(state.scheduleTimes);
    if (index < 0 || index >= updated.length) return;
    updated[index] = time;
    state = state.copyWith(scheduleTimes: _sortedScheduleTimes(updated));
  }

  void addScheduleTime() {
    final updated = List<String>.from(state.scheduleTimes)..add('12:00');
    state = state.copyWith(scheduleTimes: _sortedScheduleTimes(updated));
  }

  void removeScheduleTime(int index) {
    if (state.scheduleTimes.length <= 1) return;
    final updated = List<String>.from(state.scheduleTimes)..removeAt(index);
    state = state.copyWith(scheduleTimes: updated);
  }

  List<String>? _effectiveScheduleTimes() {
    if (!state.scheduleAtSpecificTimes) return null;
    return _sortedScheduleTimes(state.scheduleTimes);
  }

  List<String> _sortedScheduleTimes(List<String> times) {
    final copy = List<String>.from(times);
    copy.sort();
    return copy;
  }

  HealthEntryMarkCompletedPrompt? markCompletedPromptIfNeeded() {
    if (state.isRecordMode ||
        state.isEdit ||
        state.frequency != HealthFrequency.once ||
        state.completedOn != null ||
        state.dueDate == null) {
      return null;
    }

    final today = DateTime.now();
    final dueOnly = calendarDateOnly(state.dueDate!);
    final todayOnly = calendarDateOnly(today);
    if (dueOnly.isAfter(todayOnly)) return null;

    return HealthEntryMarkCompletedPrompt(
      dueOnly: dueOnly,
      todayOnly: todayOnly,
      isPast: dueOnly.isBefore(todayOnly),
    );
  }

  void applyMarkCompleted(bool markCompleted) {
    if (!markCompleted) return;
    final prompt = markCompletedPromptIfNeeded();
    if (prompt == null) return;
    state = state.copyWith(completedOn: prompt.dueOnly);
  }

  Future<HealthEntrySubmitOutcome> submit({
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
      final notifier = ref.read(healthEntriesNotifierProvider.notifier);
      final isRecord = state.isRecordMode;
      final effectiveFrequency =
          isRecord ? HealthFrequency.once : state.frequency;
      final effectiveRepeatEndDate = isRecord || effectiveFrequency == HealthFrequency.once
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
      final effectiveScheduleTimes =
          isRecord ? null : _effectiveScheduleTimes();
      final careFamily = resolveCareFamilyForWrite(
        frequency: state.frequency,
        type: state.type,
        selected: state.careFamily,
        existing: state.loadedUncategorised ? null : state.careFamily,
        isCreate: !state.isEdit,
      );

      if (state.isEdit) {
        final entry = HealthEntry(
          id: _entryId ?? '',
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
        if (state.pendingPhotos.isNotEmpty && _entryId != null) {
          final filesToUpload = List<XFile>.from(state.pendingPhotos);
          await uploadPendingPhotosToEntry(_entryId!, filesToUpload);
          clearPendingPhotos();
          await loadPhotos();
        }
      } else {
        final createUseCase = ref.read(createHealthEntryProvider);
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
          for (final entryId in createdEntryIds) {
            await uploadPendingPhotosToEntry(entryId, filesToUpload);
          }
          clearPendingPhotos();
        }
        await notifier.refresh();
      }

      return HealthEntrySubmitSuccess(
        isEdit: state.isEdit,
        petIds: Set<String>.from(state.selectedPetIds),
        entryIds: state.isEdit
            ? (_entryId != null ? [_entryId!] : <String>[])
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

final healthEntryFormControllerProvider = StateNotifierProvider.autoDispose
    .family<
      HealthEntryFormController,
      HealthEntryFormState,
      HealthEntryFormParams
    >((ref, params) => HealthEntryFormController(ref, params));
