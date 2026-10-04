import '../entities/contact_summary.dart';
import '../enums/contact_group.dart';
import '../enums/contact_role.dart';
import '../enums/relationship_kind.dart';

class DeskRankingContext {
  const DeskRankingContext({
    this.linkedPetCountByLegacyVetId = const {},
    this.linkedPetCountByContactId = const {},
    this.primaryVetContactIds = const {},
  });

  final Map<String, int> linkedPetCountByLegacyVetId;
  final Map<String, int> linkedPetCountByContactId;
  final Set<String> primaryVetContactIds;
}

bool isVetTeamCandidate(ContactSummary contact) {
  if (contact.group != ContactGroup.professional) {
    return contact.roles.any(
      (r) => r == ContactRole.vet || r == ContactRole.vetNurse,
    );
  }
  if (contact.roles.any((r) => r == ContactRole.vet || r == ContactRole.vetNurse)) {
    return true;
  }
  return contact.pets.any(
    (p) =>
        p.relationshipKind == RelationshipKind.primaryVet ||
        p.relationshipKind == RelationshipKind.outOfHoursVet,
  );
}

int _vetTeamScore(ContactSummary contact, DeskRankingContext ctx) {
  var score = 0;
  score += ctx.linkedPetCountByLegacyVetId[contact.legacyVetId ?? ''] ?? 0;
  score += ctx.linkedPetCountByContactId[contact.id] ?? 0;
  if (ctx.primaryVetContactIds.contains(contact.id)) score += 10;
  if (contact.pets.any((p) => p.isPrimary)) score += 5;
  return score;
}

List<ContactSummary> rankVetTeamContacts(
  List<ContactSummary> contacts,
  DeskRankingContext ctx, {
  int limit = 2,
}) {
  final candidates =
      contacts.where(isVetTeamCandidate).where((c) => !c.isInactive).toList();
  candidates.sort((a, b) {
    final scoreDiff = _vetTeamScore(b, ctx).compareTo(_vetTeamScore(a, ctx));
    if (scoreDiff != 0) return scoreDiff;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return candidates.take(limit).toList();
}

int _carerScore(ContactSummary contact) {
  var score = contact.pets.length;
  if (contact.nextAbsence != null) score += 100;
  return score;
}

List<ContactSummary> rankTrustedCarerContacts(
  List<ContactSummary> contacts, {
  int limit = 2,
}) {
  final carers = contacts
      .where((c) => c.group == ContactGroup.carer && !c.isInactive)
      .toList();
  carers.sort((a, b) {
    final scoreDiff = _carerScore(b).compareTo(_carerScore(a));
    if (scoreDiff != 0) return scoreDiff;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return carers.take(limit).toList();
}
