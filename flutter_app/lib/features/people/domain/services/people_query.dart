import '../entities/contact_summary.dart';
import '../entities/household.dart';
import '../entities/roster.dart';
import '../enums/contact_group.dart';
import '../enums/contact_kind.dart';
import '../enums/contact_role.dart';
import '../enums/contact_status.dart';
import 'roster_search.dart';

/// Filters roster contacts (and optional household members) for [PeoplePickerSheet].
class PeopleQuery {
  const PeopleQuery({
    this.groups,
    this.roles,
    this.kinds,
    this.includeHouseholdMembers = false,
    this.currentId,
    this.allowNone = false,
    this.allowTypedName = false,
    this.petId,
  });

  final Set<ContactGroup>? groups;
  final Set<ContactRole>? roles;
  final Set<ContactKind>? kinds;
  final bool includeHouseholdMembers;
  final String? currentId;
  final bool allowNone;
  final bool allowTypedName;
  final String? petId;
}

sealed class PeoplePickerOption {
  const PeoplePickerOption();

  String get optionId;
  String get displayName;
}

final class ContactPickerOption extends PeoplePickerOption {
  const ContactPickerOption(this.contact);

  final ContactSummary contact;

  @override
  String get optionId => contact.id;

  @override
  String get displayName => contact.name;
}

final class HouseholdMemberPickerOption extends PeoplePickerOption {
  const HouseholdMemberPickerOption({
    required this.household,
    required this.member,
  });

  final Household household;
  final HouseholdMember member;

  @override
  String get optionId => member.userId;

  @override
  String get displayName => member.displayName;
}

class PeoplePickerSection {
  const PeoplePickerSection({required this.titleKey, required this.options});

  /// l10n key or household name when [titleKey] is a raw title.
  final String titleKey;
  final List<PeoplePickerOption> options;
}

class PeoplePickerData {
  const PeoplePickerData({this.pinned, required this.sections});

  final PeoplePickerOption? pinned;
  final List<PeoplePickerSection> sections;
}

PeoplePickerData buildPeoplePickerData(Roster roster, PeopleQuery query) {
  PeoplePickerOption? pinned;
  if (query.currentId != null) {
    pinned = _optionForId(roster, query.currentId!);
  }

  final contacts = roster.contacts.where((c) {
    if (c.status == ContactStatus.inactive && c.id != query.currentId) {
      return false;
    }
    if (query.groups != null && !query.groups!.contains(c.group)) return false;
    if (query.kinds != null && !query.kinds!.contains(c.kind)) return false;
    if (query.roles != null && query.roles!.isNotEmpty) {
      final hasRole = c.roles.any((r) => query.roles!.contains(r));
      if (!hasRole) return false;
    }
    if (query.petId != null) {
      final linked = c.pets.any((p) => p.petId == query.petId);
      if (!linked) return false;
    }
    if (query.currentId != null && c.id == query.currentId) {
      return false;
    }
    return true;
  }).toList();

  final memberOptions = <PeoplePickerOption>[];
  if (query.includeHouseholdMembers) {
    for (final household in roster.households) {
      for (final member in household.members) {
        if (query.currentId != null && member.userId == query.currentId) {
          continue;
        }
        memberOptions.add(
          HouseholdMemberPickerOption(household: household, member: member),
        );
      }
    }
  }

  final sections = <PeoplePickerSection>[];

  if (memberOptions.isNotEmpty) {
    sections.add(
      PeoplePickerSection(
        titleKey: 'peoplePickerHouseholdMembersSection',
        options: memberOptions,
      ),
    );
  }

  final carers = contacts
      .where((c) => c.group == ContactGroup.carer)
      .toList(growable: false);
  final professionals = contacts
      .where((c) => c.group == ContactGroup.professional)
      .toList(growable: false);

  final showGrouped = query.groups == null || query.groups!.length > 1;

  if (showGrouped) {
    if (carers.isNotEmpty &&
        (query.groups == null || query.groups!.contains(ContactGroup.carer))) {
      sections.add(
        PeoplePickerSection(
          titleKey: 'peopleGroupCarers',
          options: carers.map(ContactPickerOption.new).toList(),
        ),
      );
    }
    if (professionals.isNotEmpty &&
        (query.groups == null ||
            query.groups!.contains(ContactGroup.professional))) {
      sections.add(
        PeoplePickerSection(
          titleKey: 'peopleGroupProfessionals',
          options: professionals.map(ContactPickerOption.new).toList(),
        ),
      );
    }
  } else if (contacts.isNotEmpty) {
    sections.add(
      PeoplePickerSection(
        titleKey: 'peoplePickerContactsSection',
        options: contacts.map(ContactPickerOption.new).toList(),
      ),
    );
  }

  return PeoplePickerData(pinned: pinned, sections: sections);
}

List<PeoplePickerOption> filterPickerOptions(
  List<PeoplePickerOption> options,
  String searchQuery,
) {
  final q = normalizePeopleQuery(searchQuery);
  if (q.isEmpty) return options;
  return options.where((o) {
    if (o is ContactPickerOption) {
      return contactMatchesQuery(o.contact, searchQuery);
    }
    return o.displayName.toLowerCase().contains(q);
  }).toList();
}

PeoplePickerOption? _optionForId(Roster roster, String id) {
  for (final c in roster.contacts) {
    if (c.id == id) return ContactPickerOption(c);
  }
  for (final household in roster.households) {
    for (final member in household.members) {
      if (member.userId == id) {
        return HouseholdMemberPickerOption(
          household: household,
          member: member,
        );
      }
    }
  }
  return null;
}
