import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/foster_session_status.dart';

bool isActiveFosterPlacementStatus(String? status) {
  return status == 'pending' ||
      status == 'in_progress' ||
      status == 'waiting_adoption_confirmation' ||
      status == 'pending_adoption_conditions';
}

bool isActiveFosterSessionStatus(String? sessionStatus) {
  if (sessionStatus == null || sessionStatus.isEmpty) return false;
  return FosterSessionStatus.isOpen(sessionStatus);
}

String fosterSessionStatusLabel(AppLocalizations l, String? sessionStatus) {
  switch (sessionStatus) {
    case FosterSessionStatus.pendingAcceptance:
      return l.fosteringSessionStatusPendingAcceptance;
    case FosterSessionStatus.preparation:
      return l.fosteringSessionStatusPreparation;
    case FosterSessionStatus.readyToStart:
      return l.fosteringSessionStatusReadyToStart;
    case FosterSessionStatus.active:
      return l.fosteringSessionStatusActive;
    case FosterSessionStatus.endPendingConfirmation:
      return l.fosteringSessionStatusEndPending;
    case FosterSessionStatus.adoptionInProgress:
      return l.fosteringSessionStatusAdoptionInProgress;
    case FosterSessionStatus.returnedToShelter:
      return l.fosteringSessionStatusReturned;
    case FosterSessionStatus.transferred:
      return l.fosteringSessionStatusTransferred;
    case FosterSessionStatus.convertedToAdoption:
      return l.fosteringSessionStatusConvertedToAdoption;
    case FosterSessionStatus.cancelled:
      return l.fosteringSessionStatusCancelled;
    default:
      return fosterPlacementStatusLabel(l, sessionStatus);
  }
}

String fosterPlacementStatusLabel(AppLocalizations l, String? status) {
  switch (status) {
    case 'pending':
      return l.fosterPlacementPending;
    case 'in_progress':
      return l.fosterPlacementInProgress;
    case 'pending_adoption_conditions':
      return l.pendingAdoptionConditions;
    case 'waiting_adoption_confirmation':
      return l.waitingAdoptionConfirmation;
    default:
      return l.fosterPlacementNotInFosterShort;
  }
}

String fosterPlacementSummary(
  AppLocalizations l, {
  required String? status,
  String? sessionStatus,
  String? fosterName,
}) {
  final label = sessionStatus != null && sessionStatus.isNotEmpty
      ? fosterSessionStatusLabel(l, sessionStatus)
      : fosterPlacementStatusLabel(l, status);
  final active = sessionStatus != null && sessionStatus.isNotEmpty
      ? isActiveFosterSessionStatus(sessionStatus)
      : isActiveFosterPlacementStatus(status);
  if (active && fosterName != null && fosterName.isNotEmpty) {
    return '$label · $fosterName';
  }
  return label;
}

String? petFosterPlacementCardLine(AppLocalizations l, Pet pet) {
  if (pet.organizationId == null) return null;
  return fosterPlacementSummary(
    l,
    status: pet.fosterPlacementStatus,
    fosterName: pet.fosterName,
  );
}
