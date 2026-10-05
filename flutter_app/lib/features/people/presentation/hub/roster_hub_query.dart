import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter.dart';

import '../../domain/entities/contact_summary.dart';
import '../../domain/entities/household_invite.dart';
import '../../domain/entities/roster.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_kind.dart';
import '../../domain/enums/contact_status.dart';
import '../../domain/services/roster_search.dart';
import '../../domain/services/roster_sections.dart';

abstract final class PeopleRosterFilterIds {
  static const group = 'group';
  static const kind = 'kind';
  static const pet = 'pet';
  static const status = 'status';

  static const groupHousehold = 'household';
  static const groupCarers = 'carers';
  static const groupProfessionals = 'professionals';
  static const kindPerson = 'person';
  static const kindOrganisation = 'organisation';
  static const statusActive = 'active';
  static const statusInactive = 'inactive';
}

class RosterHubQuery {
  const RosterHubQuery({
    required this.searchQuery,
    required this.filterSelections,
  });

  final String searchQuery;
  final CollectionFilterSelections filterSelections;

  factory RosterHubQuery.fromUri(Uri uri) {
    final q = uri.queryParameters['q']?.trim() ?? '';
    final selections = <String, Set<String>>{
      PeopleRosterFilterIds.group: {},
      PeopleRosterFilterIds.kind: {},
      PeopleRosterFilterIds.pet: {},
      PeopleRosterFilterIds.status: {},
    };

    final legacyFilter = uri.queryParameters['filter'];
    if (legacyFilter != null && legacyFilter.isNotEmpty) {
      switch (legacyFilter) {
        case 'household':
          selections[PeopleRosterFilterIds.group] = {
            PeopleRosterFilterIds.groupHousehold,
          };
        case 'carers':
          selections[PeopleRosterFilterIds.group] = {
            PeopleRosterFilterIds.groupCarers,
          };
        case 'professionals':
          selections[PeopleRosterFilterIds.group] = {
            PeopleRosterFilterIds.groupProfessionals,
          };
      }
    }

    _mergeCsvParam(
      selections,
      PeopleRosterFilterIds.group,
      uri.queryParameters['group'],
    );
    _mergeCsvParam(
      selections,
      PeopleRosterFilterIds.kind,
      uri.queryParameters['kind'],
    );
    _mergeCsvParam(
      selections,
      PeopleRosterFilterIds.pet,
      uri.queryParameters['pet'],
    );
    _mergeCsvParam(
      selections,
      PeopleRosterFilterIds.status,
      uri.queryParameters['status'],
    );

    return RosterHubQuery(searchQuery: q, filterSelections: selections);
  }

  Map<String, String> toQueryParameters({Map<String, String> base = const {}}) {
    final out = Map<String, String>.from(base);
    out.remove('filter');
    if (searchQuery.isNotEmpty) {
      out['q'] = searchQuery;
    } else {
      out.remove('q');
    }

    out.remove('group');
    out.remove('kind');
    out.remove('pet');
    out.remove('status');

    final group = filterSelections[PeopleRosterFilterIds.group] ?? {};
    if (group.length == 1) {
      final only = group.first;
      if (only == PeopleRosterFilterIds.groupProfessionals) {
        out['filter'] = 'professionals';
      } else if (only == PeopleRosterFilterIds.groupCarers) {
        out['filter'] = 'carers';
      } else if (only == PeopleRosterFilterIds.groupHousehold) {
        out['filter'] = 'household';
      } else {
        out['group'] = group.join(',');
      }
    } else if (group.isNotEmpty) {
      out['group'] = group.join(',');
    }

    final kind = filterSelections[PeopleRosterFilterIds.kind] ?? {};
    if (kind.isNotEmpty) out['kind'] = kind.join(',');

    final pet = filterSelections[PeopleRosterFilterIds.pet] ?? {};
    if (pet.isNotEmpty) out['pet'] = pet.join(',');

    final status = filterSelections[PeopleRosterFilterIds.status] ?? {};
    if (status.isNotEmpty) out['status'] = status.join(',');

    return out;
  }

  static void _mergeCsvParam(
    Map<String, Set<String>> selections,
    String dimension,
    String? raw,
  ) {
    if (raw == null || raw.isEmpty) return;
    selections[dimension] = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }
}

bool rosterContactMatchesFilters(ContactSummary contact, RosterHubQuery query) {
  final selections = query.filterSelections;
  final group = selections[PeopleRosterFilterIds.group] ?? {};
  if (group.isNotEmpty) {
    final inHousehold =
        contact.directory.isHousehold && contact.status == ContactStatus.active;
    final matchesGroup =
        (group.contains(PeopleRosterFilterIds.groupHousehold) && inHousehold) ||
        (group.contains(PeopleRosterFilterIds.groupCarers) &&
            contact.group == ContactGroup.carer &&
            contact.status == ContactStatus.active) ||
        (group.contains(PeopleRosterFilterIds.groupProfessionals) &&
            contact.group == ContactGroup.professional &&
            contact.status == ContactStatus.active);
    if (!matchesGroup) return false;
  }

  final kind = selections[PeopleRosterFilterIds.kind] ?? {};
  if (kind.isNotEmpty) {
    final contactKind = contact.kind == ContactKind.person
        ? PeopleRosterFilterIds.kindPerson
        : PeopleRosterFilterIds.kindOrganisation;
    if (!kind.contains(contactKind)) return false;
  }

  final pet = selections[PeopleRosterFilterIds.pet] ?? {};
  if (pet.isNotEmpty) {
    final petIds = contact.pets.map((p) => p.petId).toSet();
    if (!pet.any(petIds.contains)) return false;
  }

  final status = selections[PeopleRosterFilterIds.status] ?? {};
  if (status.isNotEmpty) {
    final activeSelected = status.contains(PeopleRosterFilterIds.statusActive);
    final inactiveSelected = status.contains(
      PeopleRosterFilterIds.statusInactive,
    );
    if (contact.status == ContactStatus.active && !activeSelected) return false;
    if (contact.status == ContactStatus.inactive && !inactiveSelected) {
      return false;
    }
  }

  return contactMatchesQuery(contact, query.searchQuery);
}

bool rosterInviteMatchesQuery(HouseholdInvite invite, RosterHubQuery query) {
  if (query.searchQuery.isEmpty) return true;
  final q = normalizePeopleQuery(query.searchQuery);
  return invite.email.toLowerCase().contains(q);
}

bool rosterSectionVisibleForFilters(
  RosterSectionKind kind,
  RosterHubQuery query,
) {
  final group = query.filterSelections[PeopleRosterFilterIds.group] ?? {};
  if (group.isEmpty) return true;
  return switch (kind) {
    RosterSectionKind.household => group.contains(
      PeopleRosterFilterIds.groupHousehold,
    ),
    RosterSectionKind.trustedCarers => group.contains(
      PeopleRosterFilterIds.groupCarers,
    ),
    RosterSectionKind.petProfessionals => group.contains(
      PeopleRosterFilterIds.groupProfessionals,
    ),
    RosterSectionKind.pendingInvites => true,
    RosterSectionKind.inactive => () {
      final status = query.filterSelections[PeopleRosterFilterIds.status] ?? {};
      if (status.isEmpty) return true;
      return status.contains(PeopleRosterFilterIds.statusInactive);
    }(),
  };
}

List<ContactSummary> filterRosterContacts(Roster roster, RosterHubQuery query) {
  return roster.contacts
      .where((c) => rosterContactMatchesFilters(c, query))
      .toList();
}
