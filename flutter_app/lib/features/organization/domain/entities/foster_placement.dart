import '../../../../core/utils/calendar_date.dart';
import 'foster_session_status.dart';

class FosterPlacement {
  const FosterPlacement({
    required this.id,
    required this.organizationId,
    required this.petId,
    required this.fosterUserId,
    required this.status,
    this.sessionStatus = FosterSessionStatus.cancelled,
    this.sessionType = FosterSessionType.standardFoster,
    this.shelterFosterRelationshipId,
    this.shelterStartConfirmedAt,
    this.fosterStartConfirmedAt,
    this.petName = '',
    this.petSpecies = '',
    this.organizationName = '',
    this.fosterName = '',
    this.fosterEmail = '',
    this.startDate,
    this.endDate,
    this.notes = '',
    this.adoptionConditions = '',
    this.createdBy,
    this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String organizationId;
  final String petId;
  final String fosterUserId;
  final String status;
  final String sessionStatus;
  final String sessionType;
  final String? shelterFosterRelationshipId;
  final DateTime? shelterStartConfirmedAt;
  final DateTime? fosterStartConfirmedAt;
  final String petName;
  final String petSpecies;
  final String organizationName;
  final String fosterName;
  final String fosterEmail;
  final DateTime? startDate;
  final DateTime? endDate;
  final String notes;
  final String adoptionConditions;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isWaitingAdoption => status == 'waiting_adoption_confirmation';
  bool get isPendingConditions => status == 'pending_adoption_conditions';
  bool get isAdopted => status == 'adopted';
  bool get isNotInFoster => status == 'not_in_foster';
  bool get isActive =>
      isPending || isInProgress || isWaitingAdoption || isPendingConditions;
  bool get isAdoptionInProgress => isWaitingAdoption || isPendingConditions;

  bool get isSessionPendingAcceptance =>
      sessionStatus == FosterSessionStatus.pendingAcceptance;
  bool get isSessionPreparation =>
      sessionStatus == FosterSessionStatus.preparation;
  bool get isSessionReadyToStart =>
      sessionStatus == FosterSessionStatus.readyToStart;
  bool get isSessionActive => sessionStatus == FosterSessionStatus.active;
  bool get isSessionEndPending =>
      sessionStatus == FosterSessionStatus.endPendingConfirmation;
  bool get isSessionAdoptionInProgress =>
      sessionStatus == FosterSessionStatus.adoptionInProgress;
  bool get isSessionOpen => FosterSessionStatus.isOpen(sessionStatus);
  bool get isSessionTerminal => FosterSessionStatus.isTerminal(sessionStatus);
  bool get shelterStartConfirmed => shelterStartConfirmedAt != null;
  bool get fosterStartConfirmed => fosterStartConfirmedAt != null;

  factory FosterPlacement.fromJson(Map<String, dynamic> json) {
    final legacyStatus = json['status']?.toString() ?? 'not_in_foster';
    final sessionStatus = json['session_status']?.toString();
    return FosterPlacement(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      fosterUserId: json['foster_user_id']?.toString() ?? '',
      status: legacyStatus,
      sessionStatus: sessionStatus != null && sessionStatus.isNotEmpty
          ? sessionStatus
          : FosterSessionStatus.fromLegacyStatus(legacyStatus),
      sessionType:
          json['session_type']?.toString() ?? FosterSessionType.standardFoster,
      shelterFosterRelationshipId: json['shelter_foster_relationship_id']
          ?.toString(),
      shelterStartConfirmedAt: json['shelter_start_confirmed_at'] != null
          ? DateTime.tryParse(json['shelter_start_confirmed_at'].toString())
          : null,
      fosterStartConfirmedAt: json['foster_start_confirmed_at'] != null
          ? DateTime.tryParse(json['foster_start_confirmed_at'].toString())
          : null,
      petName: json['pet_name']?.toString() ?? '',
      petSpecies: json['pet_species']?.toString() ?? '',
      organizationName: json['organization_name']?.toString() ?? '',
      fosterName: json['foster_name']?.toString() ?? '',
      fosterEmail: json['foster_email']?.toString() ?? '',
      startDate: parseCalendarDate(json['start_date']),
      endDate: parseCalendarDate(json['end_date']),
      notes: json['notes']?.toString() ?? '',
      adoptionConditions: json['adoption_conditions']?.toString() ?? '',
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
    );
  }
}

class PetFosterPlacementState {
  const PetFosterPlacementState({required this.status, this.placement});

  final String status;
  final FosterPlacement? placement;

  bool get isNotInFoster =>
      status == 'not_in_foster' ||
      placement == null ||
      placement!.isNotInFoster ||
      placement!.isAdopted;

  factory PetFosterPlacementState.fromJson(Map<String, dynamic> json) {
    final placementJson = json['placement'];
    return PetFosterPlacementState(
      status: json['status']?.toString() ?? 'not_in_foster',
      placement: placementJson is Map<String, dynamic>
          ? FosterPlacement.fromJson(placementJson)
          : null,
    );
  }
}
