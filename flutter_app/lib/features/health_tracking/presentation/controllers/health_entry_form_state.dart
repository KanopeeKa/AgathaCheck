import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/recurrence_anchor.dart';

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
    this.scheduleAtSpecificTimes = false,
    this.scheduleTimes = const ['08:00'],
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
  final bool scheduleAtSpecificTimes;
  final List<String> scheduleTimes;

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
    bool? scheduleAtSpecificTimes,
    List<String>? scheduleTimes,
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
      scheduleAtSpecificTimes:
          scheduleAtSpecificTimes ?? this.scheduleAtSpecificTimes,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
    );
  }
}
