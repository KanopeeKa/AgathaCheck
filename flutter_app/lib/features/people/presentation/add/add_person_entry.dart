import '../../domain/enums/contact_kind.dart';
import '../../domain/enums/contact_group.dart';

/// Who the user is adding — sets kind and which later steps apply.
enum AddPersonEntry {
  household,
  carer,
  professional,
  organisation;

  ContactKind get contactKind => switch (this) {
    AddPersonEntry.organisation => ContactKind.organisation,
    _ => ContactKind.person,
  };

  bool get requiresRoles => switch (this) {
    AddPersonEntry.household => false,
    AddPersonEntry.organisation => false,
    _ => true,
  };

  bool get showsAppAccessStep => switch (this) {
    AddPersonEntry.household || AddPersonEntry.carer => true,
    _ => false,
  };

  ContactGroup? get suggestedRoleGroup => switch (this) {
    AddPersonEntry.carer => ContactGroup.carer,
    AddPersonEntry.professional => ContactGroup.professional,
    _ => null,
  };
}
