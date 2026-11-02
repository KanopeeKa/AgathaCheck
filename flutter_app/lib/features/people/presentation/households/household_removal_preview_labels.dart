import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/people_repository.dart';

String formatHouseholdRemainingAccessLine(
  AppLocalizations l,
  HouseholdRemainingAccess access,
) {
  if (access.source == 'direct_share') {
    final role = access.role == 'co_parent'
        ? l.coParent
        : l.householdCanLogCareLabel;
    return l.peopleMemberRemovalRemainingDirectShare(access.petName, role);
  }
  if (access.source == 'absence') {
    if (access.until != null && access.until!.isNotEmpty) {
      return l.peopleMemberRemovalRemainingAbsenceUntil(
        access.petName,
        access.until!,
      );
    }
    return l.peopleMemberRemovalRemainingAbsence(access.petName);
  }
  return '${access.petName} (${access.source})';
}
