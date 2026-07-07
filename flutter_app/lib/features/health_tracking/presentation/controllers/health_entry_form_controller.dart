import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/recurrence_anchor.dart';
import '../providers/health_providers.dart';
import 'health_entry_form_constants.dart';
import 'health_entry_form_outcomes.dart';

@immutable
class HealthEntryFormParams {
  const HealthEntryFormParams({
    this.entryId,
    this.petId,
    this.initialType,
    this.allowedTypes,
  });

  final String? entryId;
  final String? petId;
  final HealthEntryType? initialType;
  final List<HealthEntryType>? allowedTypes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthEntryFormParams &&
          entryId == other.entryId &&
          petId == other.petId &&
          initialType == other.initialType &&
          listEquals(allowedTypes, other.allowedTypes);

  @override
  int get hashCode => Object.hash(
    entryId,
    petId,
    initialType,
    allowedTypes == null ? null : Object.hashAll(allowedTypes!),
  );
}

class HealthEntryFormState {
  HealthEntryFormState({
    this.name = '',
    this.dosage = '',
    this.notes = '',
    this.type = HealthEntryType.medication,
    this.frequency = HealthFrequency.once,
    this.frequencyInterval = 1,
    DateTime? startDate,
    this.dueDate,
    this.completedOn,
    this.recurrenceAnchor = RecurrenceAnchor.fromCompletion,
    this.repeatEndDate,
    this.isLoading = false,
    this.isEdit = false,
    this.isUploadingPhoto = false,
    this.photos = const [],
    this.pendingPhotos = const [],
    this.remindDaysBefore = 1,
    this.selectedHealthIssueId,
    this.selectedPetIds = const {},
    this.allowedTypes,
  }) : startDate = startDate ?? DateTime.now();

  final String name;
  final String dosage;
  final String notes;
  final HealthEntryType type;
  final HealthFrequency frequency;
  final int frequencyInterval;
  final DateTime startDate;
  final DateTime? dueDate;
  final DateTime? completedOn;
  final RecurrenceAnchor recurrenceAnchor;
  final DateTime? repeatEndDate;
  final bool isLoading;
  final bool isEdit;
  final bool isUploadingPhoto;
  final List<EventPhoto> photos;
  final List<XFile> pendingPhotos;
  final int remindDaysBefore;
  final String? selectedHealthIssueId;
  final Set<String> selectedPetIds;
  final List<HealthEntryType>? allowedTypes;

  int get totalPhotoCount => photos.length + pendingPhotos.length;

  List<HealthEntryType> get selectableTypes {
    if (allowedTypes != null && allowedTypes!.isNotEmpty) {
      return allowedTypes!;
    }
    return HealthEntryType.values;
  }

  HealthEntryFormState copyWith({
    String? name,
    String? dosage,
    String? notes,
    HealthEntryType? type,
    HealthFrequency? frequency,
    int? frequencyInterval,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? completedOn,
    RecurrenceAnchor? recurrenceAnchor,
    DateTime? repeatEndDate,
    bool? isLoading,
    bool? isEdit,
    bool? isUploadingPhoto,
    List<EventPhoto>? photos,
    List<XFile>? pendingPhotos,
    int? remindDaysBefore,
    String? selectedHealthIssueId,
    Set<String>? selectedPetIds,
    List<HealthEntryType>? allowedTypes,
    bool clearDueDate = false,
    bool clearCompletedOn = false,
    bool clearRepeatEndDate = false,
    bool clearHealthIssueId = false,
  }) {
    return HealthEntryFormState(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      frequencyInterval: frequencyInterval ?? this.frequencyInterval,
      startDate: startDate ?? this.startDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completedOn: clearCompletedOn ? null : (completedOn ?? this.completedOn),
      recurrenceAnchor: recurrenceAnchor ?? this.recurrenceAnchor,
      repeatEndDate: clearRepeatEndDate
          ? null
          : (repeatEndDate ?? this.repeatEndDate),
      isLoading: isLoading ?? this.isLoading,
      isEdit: isEdit ?? this.isEdit,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      photos: photos ?? this.photos,
      pendingPhotos: pendingPhotos ?? this.pendingPhotos,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      selectedHealthIssueId: clearHealthIssueId
          ? null
          : (selectedHealthIssueId ?? this.selectedHealthIssueId),
      selectedPetIds: selectedPetIds ?? this.selectedPetIds,
      allowedTypes: allowedTypes ?? this.allowedTypes,
    );
  }
}

class HealthEntryFormController extends StateNotifier<HealthEntryFormState> {
  HealthEntryFormController(this.ref, HealthEntryFormParams params)
    : super(_initialState(params));

  final Ref ref;
  String? _entryId;

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

    return HealthEntryFormState(
      type: type,
      isEdit: params.entryId != null,
      selectedPetIds: selectedPetIds,
      allowedTypes: params.allowedTypes,
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
      );

      return true;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void setName(String name) => state = state.copyWith(name: name);

  void setDosage(String dosage) => state = state.copyWith(dosage: dosage);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void setType(HealthEntryType type) => state = state.copyWith(type: type);

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

  void setCompletedOn(DateTime? date) =>
      state = state.copyWith(completedOn: date);

  void setRemindDaysBefore(int days) =>
      state = state.copyWith(remindDaysBefore: days);

  void setSelectedHealthIssueId(String? id) => state = state.copyWith(
    selectedHealthIssueId: id,
    clearHealthIssueId: id == null,
  );

  void setSelectedPetIds(Set<String> ids) =>
      state = state.copyWith(selectedPetIds: ids, clearHealthIssueId: true);

  HealthEntryMarkCompletedPrompt? markCompletedPromptIfNeeded() {
    if (state.isEdit ||
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
    if (state.dueDate == null && state.completedOn == null) {
      return HealthEntrySubmitValidationFailed(
        HealthEntrySubmitValidation.dueOrCompletedRequired,
      );
    }
    if (state.selectedPetIds.isEmpty) {
      return HealthEntrySubmitValidationFailed(
        HealthEntrySubmitValidation.noPetsSelected,
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
    try {
      final notifier = ref.read(healthEntriesNotifierProvider.notifier);
      final effectiveRepeatEndDate = state.frequency == HealthFrequency.once
          ? null
          : state.repeatEndDate;
      final effectiveStart =
          state.dueDate ?? state.completedOn ?? state.startDate;
      final effectiveDue =
          state.frequency == HealthFrequency.once && state.completedOn != null
          ? null
          : state.dueDate;
      final effectiveCompleted = state.completedOn;

      if (state.isEdit) {
        final entry = HealthEntry(
          id: _entryId ?? '',
          petId: state.selectedPetIds.first,
          name: state.name.trim(),
          type: state.type,
          dosage: state.dosage.trim(),
          frequency: state.frequency,
          frequencyInterval: state.frequency == HealthFrequency.once
              ? 1
              : state.frequencyInterval,
          repeatEndDate: effectiveRepeatEndDate,
          startDate: effectiveStart,
          nextDueDate: effectiveDue,
          completedOn: effectiveCompleted,
          recurrenceAnchor: state.recurrenceAnchor,
          notes: state.notes.trim(),
          healthIssueId: state.selectedHealthIssueId,
          remindDaysBefore: state.remindDaysBefore,
        );
        await notifier.updateEntry(entry);
      } else {
        final createUseCase = ref.read(createHealthEntryProvider);
        final createdEntryIds = <String>[];
        for (final petId in state.selectedPetIds) {
          final entry = HealthEntry(
            id: '',
            petId: petId,
            name: state.name.trim(),
            type: state.type,
            dosage: state.dosage.trim(),
            frequency: state.frequency,
            frequencyInterval: state.frequency == HealthFrequency.once
                ? 1
                : state.frequencyInterval,
            repeatEndDate: effectiveRepeatEndDate,
            startDate: effectiveStart,
            nextDueDate: markCompleted
                ? null
                : (state.dueDate ?? effectiveStart),
            completedOn: markCompleted
                ? (state.completedOn ?? effectiveStart)
                : state.completedOn,
            recurrenceAnchor: state.recurrenceAnchor,
            notes: state.notes.trim(),
            healthIssueId: state.selectedHealthIssueId,
            remindDaysBefore: state.remindDaysBefore,
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
