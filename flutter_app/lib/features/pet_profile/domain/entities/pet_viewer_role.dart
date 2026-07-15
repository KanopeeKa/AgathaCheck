import '../../../experience/domain/entities/app_experience.dart';
import 'pet.dart';

/// How the current user relates to a pet on the detail screen.
enum PetViewerRole { guardian, sharedCarer, fosterCarer, organization }

/// Resolves [PetViewerRole] from pet flags and active experience.
class PetViewerRoleResolver {
  const PetViewerRoleResolver._();

  static PetViewerRole resolve({
    required Pet pet,
    required AppExperience experience,
  }) {
    if (pet.isFoster) return PetViewerRole.fosterCarer;
    if (pet.isShared) return PetViewerRole.sharedCarer;
    if (experience == AppExperience.organization &&
        pet.organizationId != null) {
      return PetViewerRole.organization;
    }
    return PetViewerRole.guardian;
  }
}
