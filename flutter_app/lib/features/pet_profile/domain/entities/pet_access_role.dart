/// Pet access role for the current user's relationship to a pet (wire: access_role).
enum PetProfileAccessRole { carer, coParent }

extension PetProfileAccessRoleWire on PetProfileAccessRole {
  static PetProfileAccessRole fromWire(String? value) {
    switch (value) {
      case 'co_parent':
      case 'guardian':
        return PetProfileAccessRole.coParent;
      case 'carer':
      case 'shared':
      default:
        return PetProfileAccessRole.carer;
    }
  }

  String toWire() {
    switch (this) {
      case PetProfileAccessRole.carer:
        return 'carer';
      case PetProfileAccessRole.coParent:
        return 'co_parent';
    }
  }
}
