import '../../../../l10n/app_localizations.dart';

String peopleContactRoleLabel(AppLocalizations l, String role) {
  switch (role) {
    case 'sitter':
      return l.peopleRoleSitter;
    case 'walker':
      return l.peopleRoleWalker;
    case 'vet':
      return l.peopleRoleVet;
    case 'vet_nurse':
      return l.peopleRoleVetNurse;
    case 'groomer':
      return l.peopleRoleGroomer;
    case 'trainer':
      return l.peopleRoleTrainer;
    case 'behaviourist':
      return l.peopleRoleBehaviourist;
    case 'boarding':
      return l.peopleRoleBoarding;
    case 'emergency_contact':
      return l.peopleRoleEmergencyContact;
    case 'other':
      return l.peopleRoleOther;
    default:
      return role;
  }
}

String peopleContactRolesLine(AppLocalizations l, List<String> roles) {
  if (roles.isEmpty) return '';
  return roles.map((r) => peopleContactRoleLabel(l, r)).join(' · ');
}

String peopleContactKindLabel(AppLocalizations l, String kind) {
  switch (kind) {
    case 'organisation':
      return l.peopleKindOrganisation;
    case 'person':
      return l.peopleKindPerson;
    default:
      return kind;
  }
}
