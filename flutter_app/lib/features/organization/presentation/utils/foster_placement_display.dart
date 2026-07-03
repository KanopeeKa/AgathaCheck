import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';

bool isActiveFosterPlacementStatus(String? status) {
  return status == 'pending' ||
      status == 'in_progress' ||
      status == 'waiting_adoption_confirmation' ||
      status == 'pending_adoption_conditions';
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
  String? fosterName,
}) {
  final label = fosterPlacementStatusLabel(l, status);
  if (isActiveFosterPlacementStatus(status) &&
      fosterName != null &&
      fosterName.isNotEmpty) {
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
