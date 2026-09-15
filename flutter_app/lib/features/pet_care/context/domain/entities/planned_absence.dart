import 'planned_absence_pet_carer.dart';

class PlannedAbsence {
  const PlannedAbsence({
    required this.id,
    required this.userId,
    required this.startsOn,
    required this.endsOn,
    required this.provenance,
    this.sourceRef,
    required this.status,
    required this.petIds,
    this.petCarers = const [],
    this.handoverNote,
  });

  final String id;
  final String userId;
  final String startsOn;
  final String endsOn;
  final String provenance;
  final String? sourceRef;
  final String status;
  final List<String> petIds;
  final List<PlannedAbsencePetCarer> petCarers;
  final String? handoverNote;

  bool get isCancelled => status == 'cancelled';
}

class PlannedAbsenceOverlapWarning {
  const PlannedAbsenceOverlapWarning({
    required this.petId,
    required this.conflictingAbsenceId,
    required this.conflictingStartsOn,
    required this.conflictingEndsOn,
  });

  final String petId;
  final String conflictingAbsenceId;
  final String conflictingStartsOn;
  final String conflictingEndsOn;
}

class CreatePlannedAbsenceResult {
  const CreatePlannedAbsenceResult({
    required this.absence,
    required this.overlapWarnings,
  });

  final PlannedAbsence absence;
  final List<PlannedAbsenceOverlapWarning> overlapWarnings;
}
