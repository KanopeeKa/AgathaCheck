import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_kind.dart';
import '../../domain/enums/contact_role.dart';
import '../../domain/enums/contact_status.dart';
import '../../domain/enums/relationship_kind.dart';

extension ContactRoleLabels on ContactRole {
  String label(AppLocalizations l) {
    switch (this) {
      case ContactRole.sitter:
        return l.peopleRoleSitter;
      case ContactRole.walker:
        return l.peopleRoleWalker;
      case ContactRole.vet:
        return l.peopleRoleVet;
      case ContactRole.vetNurse:
        return l.peopleRoleVetNurse;
      case ContactRole.groomer:
        return l.peopleRoleGroomer;
      case ContactRole.trainer:
        return l.peopleRoleTrainer;
      case ContactRole.behaviourist:
        return l.peopleRoleBehaviourist;
      case ContactRole.boarding:
        return l.peopleRoleBoarding;
      case ContactRole.emergencyContact:
        return l.peopleRoleEmergencyContact;
      case ContactRole.other:
        return l.peopleRoleOther;
    }
  }
}

extension ContactKindLabels on ContactKind {
  String label(AppLocalizations l) {
    switch (this) {
      case ContactKind.person:
        return l.peopleKindPerson;
      case ContactKind.organisation:
        return l.peopleKindOrganisation;
    }
  }
}

extension ContactGroupLabels on ContactGroup {
  String label(AppLocalizations l) {
    switch (this) {
      case ContactGroup.carer:
        return l.peopleGroupCarers;
      case ContactGroup.professional:
        return l.peopleGroupProfessionals;
    }
  }
}

extension ContactStatusLabels on ContactStatus {
  String label(AppLocalizations l) {
    switch (this) {
      case ContactStatus.active:
        return l.peopleStatusActive;
      case ContactStatus.inactive:
        return l.peopleStatusInactive;
    }
  }
}

extension RelationshipKindLabels on RelationshipKind {
  String label(AppLocalizations l) {
    switch (this) {
      case RelationshipKind.primaryVet:
        return l.peopleRelationshipPrimaryVet;
      case RelationshipKind.outOfHoursVet:
        return l.peopleRelationshipOutOfHoursVet;
      case RelationshipKind.emergencyContact:
        return l.peopleRelationshipEmergencyContact;
      case RelationshipKind.careProvider:
        return l.peopleRelationshipCareProvider;
      case RelationshipKind.other:
        return l.peopleRelationshipOther;
    }
  }
}

String contactRolesLine(AppLocalizations l, List<ContactRole> roles) {
  if (roles.isEmpty) return '';
  return roles.map((r) => r.label(l)).join(' · ');
}
