import '../../domain/entities/contact_summary.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/household_invite.dart';
import '../../domain/entities/roster.dart';

sealed class PersonDetailTarget {
  const PersonDetailTarget();
}

final class PersonDetailContactTarget extends PersonDetailTarget {
  const PersonDetailContactTarget({required this.contactId});

  final String contactId;
}

final class PersonDetailHouseholdMemberTarget extends PersonDetailTarget {
  const PersonDetailHouseholdMemberTarget({
    required this.household,
    required this.member,
    this.contact,
  });

  final Household household;
  final HouseholdMember member;
  final ContactSummary? contact;
}

final class PersonDetailPendingInviteTarget extends PersonDetailTarget {
  const PersonDetailPendingInviteTarget({required this.invite});

  final HouseholdInvite invite;
}

PersonDetailTarget? resolvePersonDetailTarget(Roster roster, String personId) {
  final contact = roster.summaryById(personId);
  if (contact != null) {
    return PersonDetailContactTarget(contactId: personId);
  }
  for (final invite in roster.pendingInvites) {
    if (invite.id == personId) {
      return PersonDetailPendingInviteTarget(invite: invite);
    }
  }
  for (final household in roster.households) {
    for (final member in household.members) {
      if (member.userId == personId) {
        final linked = roster.contacts
            .where((c) => c.linkedUserId == member.userId)
            .firstOrNull;
        return PersonDetailHouseholdMemberTarget(
          household: household,
          member: member,
          contact: linked,
        );
      }
    }
  }
  return null;
}

class RosterPetOption {
  const RosterPetOption({required this.petId, required this.petName});

  final String petId;
  final String petName;
}

List<RosterPetOption> rosterPetOptions(Roster roster) {
  final byId = <String, String>{};
  for (final contact in roster.contacts) {
    for (final pet in contact.pets) {
      byId.putIfAbsent(pet.petId, () => pet.petName);
    }
  }
  for (final household in roster.households) {
    for (final member in household.members) {
      for (final petId in [...member.ownsPetIds, ...member.sharesPetIds]) {
        byId.putIfAbsent(petId, () => petId);
      }
    }
  }
  return byId.entries
      .map((e) => RosterPetOption(petId: e.key, petName: e.value))
      .toList();
}

String? rosterPetName(Roster roster, String petId) {
  for (final contact in roster.contacts) {
    for (final pet in contact.pets) {
      if (pet.petId == petId) return pet.petName;
    }
  }
  return null;
}
