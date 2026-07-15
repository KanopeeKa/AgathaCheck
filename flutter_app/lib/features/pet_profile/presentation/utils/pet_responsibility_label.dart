import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../../domain/entities/pet_viewer_role.dart';

/// User-facing responsibility label for the pet detail header.
String petResponsibilityLabel(AppLocalizations l, Pet pet, PetViewerRole role) {
  switch (role) {
    case PetViewerRole.guardian:
      return l.petResponsibilityGuardian;
    case PetViewerRole.sharedCarer:
      return l.sharedWithGroupTitle(pet.guardianName ?? l.petGuardian);
    case PetViewerRole.fosterCarer:
      return l.fosteredViaGroupTitle(pet.organizationName ?? '');
    case PetViewerRole.organization:
      return l.petResponsibilityOrgCustody(pet.organizationName ?? '');
  }
}
