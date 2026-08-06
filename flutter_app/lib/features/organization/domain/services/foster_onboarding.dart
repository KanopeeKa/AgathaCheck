import '../../domain/entities/org_person.dart';

bool personCanOnboardAsFoster(OrgPersonSummary person) {
  if (person.isExternal || person.isPending) return false;
  if (person.userId == null || person.userId!.isEmpty) return false;
  return person.fosterApprovalState == null;
}
