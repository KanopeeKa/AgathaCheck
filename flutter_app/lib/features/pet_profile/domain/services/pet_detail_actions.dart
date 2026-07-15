import '../../../experience/domain/entities/app_experience.dart';
import '../entities/pet.dart';
import '../entities/pet_viewer_role.dart';

/// Actions that may appear on the pet detail screen.
enum PetDetailAction {
  editProfile,
  assignVet,
  downloadReport,
  manageSharing,
  fosterPlacement,
}

/// Registry of which pet-detail actions are visible per experience and role.
class PetDetailActions {
  const PetDetailActions._();

  static const privilegedActions = {
    PetDetailAction.editProfile,
    PetDetailAction.assignVet,
    PetDetailAction.manageSharing,
    PetDetailAction.fosterPlacement,
  };

  static Set<PetDetailAction> visible({
    required Pet pet,
    required AppExperience experience,
    required PetViewerRole role,
    bool isOrgAdmin = false,
    bool policyInputsResolved = true,
  }) {
    if (!policyInputsResolved) {
      return const {};
    }

    final actions = <PetDetailAction>{PetDetailAction.downloadReport};

    switch (role) {
      case PetViewerRole.guardian:
        actions.addAll({
          PetDetailAction.editProfile,
          PetDetailAction.assignVet,
          PetDetailAction.manageSharing,
        });
      case PetViewerRole.sharedCarer:
      case PetViewerRole.fosterCarer:
        break;
      case PetViewerRole.organization:
        if (isOrgAdmin) {
          actions.addAll({
            PetDetailAction.editProfile,
            PetDetailAction.assignVet,
            PetDetailAction.manageSharing,
            PetDetailAction.fosterPlacement,
          });
        }
    }

    return actions;
  }

  static PetDetailContext resolveContext({
    required Pet pet,
    required AppExperience experience,
    bool isOrgAdmin = false,
    bool policyInputsResolved = true,
  }) {
    final role = PetViewerRoleResolver.resolve(
      pet: pet,
      experience: experience,
    );
    return PetDetailContext(
      experience: experience,
      role: role,
      actions: visible(
        pet: pet,
        experience: experience,
        role: role,
        isOrgAdmin: isOrgAdmin,
        policyInputsResolved: policyInputsResolved,
      ),
      isPolicyResolved: policyInputsResolved,
    );
  }
}

/// Resolved viewer context for a pet detail screen.
class PetDetailContext {
  const PetDetailContext({
    required this.experience,
    required this.role,
    required this.actions,
    required this.isPolicyResolved,
  });

  final AppExperience experience;
  final PetViewerRole role;
  final Set<PetDetailAction> actions;
  final bool isPolicyResolved;

  bool can(PetDetailAction action) =>
      isPolicyResolved && actions.contains(action);

  /// Safe default while async policy inputs (pets, orgs, admin) are loading.
  factory PetDetailContext.restricted({
    AppExperience experience = AppExperience.guardian,
  }) {
    return PetDetailContext(
      experience: experience,
      role: PetViewerRole.guardian,
      actions: const {},
      isPolicyResolved: false,
    );
  }
}
