import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/health_entry.dart';

class HealthEntryFormController extends StateNotifier<HealthEntryFormState> {
  final Ref ref;
  HealthEntryFormController(this.ref) : super(HealthEntryFormState());

  // Add methods for loading, saving, picking photos, etc.
}

class HealthEntryFormState {
  final String name;
  final String dosage;
  final String notes;
  final HealthEntryType type;
  final HealthFrequency frequency;
  final int frequencyInterval;
  final DateTime startDate;
  final DateTime? nextDueDate;
  final DateTime? repeatEndDate;
  final bool isLoading;
  final bool isEdit;
  final bool isUploadingPhoto;
  final List photos;
  final List pendingPhotos;
  final int remindDaysBefore;
  final String? selectedHealthIssueId;
  final Set<String> selectedPetIds;

  HealthEntryFormState({
    this.name = '',
    this.dosage = '',
    this.notes = '',
    this.type = HealthEntryType.medication,
    this.frequency = HealthFrequency.once,
    this.frequencyInterval = 1,
    DateTime? startDate,
    this.nextDueDate,
    this.repeatEndDate,
    this.isLoading = false,
    this.isEdit = false,
    this.isUploadingPhoto = false,
    List? photos,
    List? pendingPhotos,
    this.remindDaysBefore = 1,
    this.selectedHealthIssueId,
    Set<String>? selectedPetIds,
  })  : startDate = startDate ?? DateTime.now(),
        photos = photos ?? [],
        pendingPhotos = pendingPhotos ?? [],
        selectedPetIds = selectedPetIds ?? {};

  HealthEntryFormState copyWith({
    String? name,
    String? dosage,
    String? notes,
    HealthEntryType? type,
    HealthFrequency? frequency,
    int? frequencyInterval,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? repeatEndDate,
    bool? isLoading,
    bool? isEdit,
    bool? isUploadingPhoto,
    List? photos,
    List? pendingPhotos,
    int? remindDaysBefore,
    String? selectedHealthIssueId,
    Set<String>? selectedPetIds,
  }) {
    return HealthEntryFormState(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      frequencyInterval: frequencyInterval ?? this.frequencyInterval,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      repeatEndDate: repeatEndDate ?? this.repeatEndDate,
      isLoading: isLoading ?? this.isLoading,
      isEdit: isEdit ?? this.isEdit,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      photos: photos ?? this.photos,
      pendingPhotos: pendingPhotos ?? this.pendingPhotos,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      selectedHealthIssueId: selectedHealthIssueId ?? this.selectedHealthIssueId,
      selectedPetIds: selectedPetIds ?? this.selectedPetIds,
    );
  }
}
