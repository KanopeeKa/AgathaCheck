import '../../domain/entities/org_person.dart';

/// Query-param helpers for the organisation People screen and bulk flows.
List<String> parseOrgPeopleIdsQuery(String? peopleParam) {
  if (peopleParam == null || peopleParam.trim().isEmpty) return const [];
  return peopleParam
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
}

String encodeOrgPeopleIdsQuery(Iterable<String> userIds) =>
    userIds.join(',');

bool personIsSelectableForBulk(OrgPersonSummary person) =>
    !person.isPending &&
    person.userId != null &&
    person.userId!.isNotEmpty;
