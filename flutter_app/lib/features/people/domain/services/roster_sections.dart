import '../entities/contact_summary.dart';
import '../entities/household.dart';
import '../entities/roster.dart';
import '../enums/contact_group.dart';
import '../enums/contact_status.dart';

enum RosterSectionKind {
  household,
  trustedCarers,
  petProfessionals,
  pendingInvites,
  inactive,
}

class RosterSection {
  const RosterSection({
    required this.kind,
    this.household,
    required this.titleKey,
    required this.entries,
  });

  final RosterSectionKind kind;
  final Household? household;
  final String titleKey;
  final List<ContactSummary> entries;
}

/// Builds hub sections from a roster (pure).
List<RosterSection> buildRosterSections(Roster roster) {
  final sections = <RosterSection>[];

  for (final household in roster.households) {
    final memberContactIds = household.members.map((m) => m.userId).toSet();
    final householdContacts = roster.contacts.where((c) {
      return c.directory.isHousehold &&
          c.directory.householdId == household.id &&
          c.status == ContactStatus.active;
    }).toList();
    if (householdContacts.isNotEmpty || household.members.isNotEmpty) {
      sections.add(
        RosterSection(
          kind: RosterSectionKind.household,
          household: household,
          titleKey: household.name,
          entries: householdContacts,
        ),
      );
    }
    memberContactIds.length; // reserved for member rows in later UI phases
  }

  final activeContacts = roster.contacts
      .where((c) => c.status == ContactStatus.active)
      .toList();
  final carers = activeContacts
      .where((c) => c.group == ContactGroup.carer)
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  if (carers.isNotEmpty) {
    sections.add(
      RosterSection(
        kind: RosterSectionKind.trustedCarers,
        titleKey: 'peopleTrustedCarersSection',
        entries: carers,
      ),
    );
  }

  final professionals = activeContacts
      .where((c) => c.group == ContactGroup.professional)
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  if (professionals.isNotEmpty) {
    sections.add(
      RosterSection(
        kind: RosterSectionKind.petProfessionals,
        titleKey: 'peopleProfessionalsSection',
        entries: professionals,
      ),
    );
  }

  if (roster.pendingInvites.isNotEmpty) {
    sections.add(
      const RosterSection(
        kind: RosterSectionKind.pendingInvites,
        titleKey: 'peoplePendingInvitesSection',
        entries: [],
      ),
    );
  }

  final inactive = roster.contacts
      .where((c) => c.status == ContactStatus.inactive)
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  if (inactive.isNotEmpty) {
    sections.add(
      RosterSection(
        kind: RosterSectionKind.inactive,
        titleKey: 'peopleInactiveSection',
        entries: inactive,
      ),
    );
  }

  return sections;
}
