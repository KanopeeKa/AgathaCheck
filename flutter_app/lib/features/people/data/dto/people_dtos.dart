import '../../domain/entities/contact_detail.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/entities/contact_usage.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/household_invite.dart';
import '../../domain/entities/pet_people.dart';
import '../../domain/entities/related_care.dart';
import '../../domain/entities/roster.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_kind.dart';
import '../../domain/enums/contact_role.dart';
import '../../domain/enums/contact_status.dart';
import '../../domain/enums/relationship_kind.dart';

class ContactDirectoryRefDto {
  static ContactDirectoryRef fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ContactDirectoryRef(type: 'personal');
    }
    return ContactDirectoryRef(
      type: json['type']?.toString() ?? 'personal',
      householdId: json['household_id']?.toString(),
    );
  }

  static Map<String, dynamic> toJson(ContactDirectoryRef ref) => {
    'type': ref.type,
    'household_id': ref.householdId,
  };
}

class ContactPetLinkDto {
  static ContactPetLink fromJson(Map<String, dynamic> json) => ContactPetLink(
    petId: json['pet_id']?.toString() ?? '',
    petName: json['pet_name']?.toString() ?? '',
    relationshipKind: RelationshipKind.fromWire(
      json['relationship_kind']?.toString(),
    ),
    isPrimary: json['is_primary'] == true,
  );

  static Map<String, dynamic> toJson(ContactPetLink link) => {
    'pet_id': link.petId,
    'pet_name': link.petName,
    'relationship_kind': link.relationshipKind.wireValue,
    'is_primary': link.isPrimary,
  };
}

class ContactSummaryDto {
  static ContactSummary fromJson(Map<String, dynamic> json) {
    final accessRaw = json['access'];
    ContactAccessLine? access;
    if (accessRaw is Map<String, dynamic>) {
      access = ContactAccessLine(
        role: accessRaw['role']?.toString() ?? '',
        petId: accessRaw['pet_id']?.toString(),
        expiresAt: accessRaw['expires_at'] != null
            ? DateTime.tryParse(accessRaw['expires_at'].toString())
            : null,
      );
    }
    ContactWorksAt? worksAt;
    final worksAtRaw = json['works_at'];
    if (worksAtRaw is Map<String, dynamic>) {
      worksAt = ContactWorksAt(
        id: worksAtRaw['id']?.toString() ?? '',
        name: worksAtRaw['name']?.toString() ?? '',
      );
    }
    ContactNextAbsence? nextAbsence;
    final absenceRaw = json['next_absence'];
    if (absenceRaw is Map<String, dynamic>) {
      nextAbsence = ContactNextAbsence(
        absenceId: absenceRaw['absence_id']?.toString() ?? '',
        startsOn: absenceRaw['starts_on']?.toString() ?? '',
        endsOn: absenceRaw['ends_on']?.toString() ?? '',
        petIds: (absenceRaw['pet_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    }
    return ContactSummary(
      id: json['id']?.toString() ?? '',
      directory: ContactDirectoryRefDto.fromJson(
        json['directory'] as Map<String, dynamic>?,
      ),
      kind: ContactKind.fromWire(json['kind']?.toString()),
      name: json['name']?.toString() ?? '',
      roles: ContactRole.fromWireList(json['roles'] as List?),
      group: ContactGroup.fromWire(json['group']?.toString()),
      status: ContactStatus.fromWire(json['status']?.toString()),
      linkedUserId: json['linked_user_id']?.toString(),
      pets: (json['pets'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ContactPetLinkDto.fromJson)
          .toList(),
      worksAt: worksAt,
      nextAbsence: nextAbsence,
      access: access,
      linkedVetRecordId: json['legacy_vet_id']?.toString(),
      inactiveAt: json['inactive_at'] != null
          ? DateTime.tryParse(json['inactive_at'].toString())
          : null,
    );
  }

  static Map<String, dynamic> toJson(ContactSummary summary) => {
    'id': summary.id,
    'directory': ContactDirectoryRefDto.toJson(summary.directory),
    'kind': summary.kind.wireValue,
    'name': summary.name,
    'roles': summary.roles.map((r) => r.wireValue).toList(),
    'group': summary.group.wireValue,
    'status': summary.status.wireValue,
    'linked_user_id': summary.linkedUserId,
    'pets': summary.pets.map(ContactPetLinkDto.toJson).toList(),
    if (summary.worksAt != null)
      'works_at': {'id': summary.worksAt!.id, 'name': summary.worksAt!.name},
    if (summary.nextAbsence != null)
      'next_absence': {
        'absence_id': summary.nextAbsence!.absenceId,
        'starts_on': summary.nextAbsence!.startsOn,
        'ends_on': summary.nextAbsence!.endsOn,
        'pet_ids': summary.nextAbsence!.petIds,
      },
    'legacy_vet_id': summary.linkedVetRecordId,
  };
}

class ContactDetailDto {
  static ContactDetail fromJson(Map<String, dynamic> json) {
    final summary = ContactSummaryDto.fromJson(json);
    ContactWorksAtDetail? worksAt;
    final worksAtRaw = json['works_at'];
    if (worksAtRaw is Map<String, dynamic>) {
      worksAt = ContactWorksAtDetail(
        id: worksAtRaw['id']?.toString() ?? '',
        name: worksAtRaw['name']?.toString() ?? '',
        phone: worksAtRaw['phone']?.toString(),
        email: worksAtRaw['email']?.toString(),
        address: worksAtRaw['address']?.toString(),
      );
    }
    LinkedAccount? linked;
    final linkedRaw = json['linked_account'];
    if (linkedRaw is Map<String, dynamic>) {
      linked = LinkedAccount(
        userId: linkedRaw['user_id']?.toString() ?? '',
        displayName: linkedRaw['display_name']?.toString() ?? '',
        photoUrl: linkedRaw['photo_url']?.toString(),
      );
    }
    final staff = (json['staff'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => ContactStaffMember(
            id: row['id']?.toString() ?? '',
            name: row['name']?.toString() ?? '',
            kind: ContactKind.fromWire(row['kind']?.toString()),
            roles: ContactRole.fromWireList(row['roles'] as List?),
          ),
        )
        .toList();
    final usageCountsRaw = json['usage_counts'];
    final usageCounts = <String, int>{};
    if (usageCountsRaw is Map) {
      for (final entry in usageCountsRaw.entries) {
        usageCounts[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
      }
    }
    return ContactDetail(
      id: summary.id,
      directoryId: json['directory_id']?.toString() ?? '',
      directory: summary.directory,
      kind: summary.kind,
      name: summary.name,
      roles: summary.roles,
      group: summary.group,
      status: summary.status,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      website: json['website']?.toString(),
      worksAtContactId: json['works_at_contact_id']?.toString(),
      linkedUserId: summary.linkedUserId,
      inactiveAt: json['inactive_at'] != null
          ? DateTime.tryParse(json['inactive_at'].toString())
          : null,
      linkedVetRecordId: summary.linkedVetRecordId,
      privateNote: json['private_note']?.toString() ?? '',
      householdNote: json['household_note']?.toString(),
      worksAt: worksAt,
      staff: staff,
      usageCounts: usageCounts,
      linkedAccount: linked,
    );
  }
}

class ContactUsageDto {
  static ContactUsage fromJson(Map<String, dynamic> json) => ContactUsage(
    kind: json['kind']?.toString() ?? '',
    id: json['id']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    petId: json['pet_id']?.toString(),
    active: json['active'] as bool?,
  );
}

class HouseholdDto {
  static Household fromJson(Map<String, dynamic> json) {
    final pets = (json['pets'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (p) => HouseholdPet(
            petId: p['pet_id']?.toString() ?? '',
            name: p['name']?.toString() ?? '',
            ownerUserId: p['owner_user_id']?.toString() ?? '',
          ),
        )
        .toList();
    final members = (json['members'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) => _memberFromJson(m, pets))
        .toList();
    return Household(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      myTier:
          json['my_tier']?.toString() ??
          json['my_access_tier']?.toString() ??
          '',
      myIsOrganiser: json['my_is_organiser'] == true,
      members: members,
      pets: pets,
    );
  }

  static HouseholdMember _memberFromJson(
    Map<String, dynamic> m,
    List<HouseholdPet> pets,
  ) {
    if (m['display_name'] != null) {
      return HouseholdMember(
        userId: m['user_id']?.toString() ?? '',
        displayName: m['display_name']?.toString() ?? '',
        firstName: m['first_name']?.toString() ?? '',
        tier: m['tier']?.toString() ?? '',
        isOrganiser: m['is_organiser'] == true,
        isYou: m['is_you'] == true,
        ownsPetIds: (m['owns_pet_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        sharesPetIds: (m['shares_pet_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    }
    final user = m['user'] as Map<String, dynamic>?;
    final firstName =
        user?['first_name']?.toString() ?? m['first_name']?.toString() ?? '';
    final lastName = user?['last_name']?.toString() ?? '';
    final displayName = [
      firstName,
      lastName,
    ].where((s) => s.isNotEmpty).join(' ').trim();
    final userId = m['user_id']?.toString() ?? '';
    final owns = pets
        .where((p) => p.ownerUserId == userId)
        .map((p) => p.petId)
        .toList();
    final shares = pets
        .where((p) => p.ownerUserId != userId)
        .map((p) => p.petId)
        .toList();
    return HouseholdMember(
      userId: userId,
      displayName: displayName.isEmpty ? 'Member' : displayName,
      firstName: firstName,
      tier: m['tier']?.toString() ?? m['access_tier']?.toString() ?? '',
      isOrganiser: m['is_organiser'] == true,
      isYou: m['is_you'] == true,
      ownsPetIds: owns,
      sharesPetIds: shares,
    );
  }
}

class HouseholdInviteDto {
  static HouseholdInvite fromJson(Map<String, dynamic> json) => HouseholdInvite(
    id: json['id']?.toString() ?? '',
    source: json['source']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    contactId: json['contact_id']?.toString(),
    householdId: json['household_id']?.toString(),
    petIds: (json['pet_ids'] as List? ?? []).map((e) => e.toString()).toList(),
    createdAt: json['created_at']?.toString(),
  );
}

class RosterDto {
  static Roster fromJson(Map<String, dynamic> json) => Roster(
    households: (json['households'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(HouseholdDto.fromJson)
        .toList(),
    contacts: (json['contacts'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ContactSummaryDto.fromJson)
        .toList(),
    pendingInvites: (json['pending_invites'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(HouseholdInviteDto.fromJson)
        .toList(),
  );
}

class RelatedCareDto {
  static RelatedCare fromJson(Map<String, dynamic> json) => RelatedCare(
    pets: (json['pets'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (p) => RelatedCarePet(
            petId: p['pet_id']?.toString() ?? '',
            petName: p['pet_name']?.toString() ?? '',
            relationshipKind: RelationshipKind.fromWire(
              p['relationship_kind']?.toString(),
            ),
          ),
        )
        .toList(),
    careItems: (json['care_items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (c) => RelatedCareItem(
            id: c['id']?.toString() ?? '',
            name: c['name']?.toString() ?? '',
            petId: c['pet_id']?.toString() ?? '',
          ),
        )
        .toList(),
    absences: (json['absences'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (a) => RelatedCareAbsence(
            absenceId: a['absence_id']?.toString() ?? '',
            startsOn: a['starts_on']?.toString() ?? '',
            endsOn: a['ends_on']?.toString() ?? '',
            petIds: (a['pet_ids'] as List? ?? [])
                .map((e) => e.toString())
                .toList(),
          ),
        )
        .toList(),
    historyCount: (json['history_count'] as num?)?.toInt() ?? 0,
  );
}

class PetPeopleDto {
  static PetPeople fromJson(Map<String, dynamic> json) {
    final ownerRaw = json['owner'] as Map<String, dynamic>? ?? {};
    return PetPeople(
      petId: json['pet_id']?.toString() ?? '',
      petName: json['pet_name']?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
      owner: PetPeopleOwner(
        userId: ownerRaw['user_id']?.toString() ?? '',
        displayName: ownerRaw['display_name']?.toString() ?? '',
      ),
      householdMembers: (json['household_members'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (m) => HouseholdMemberSnapshot(
              userId: m['user_id']?.toString() ?? '',
              displayName: m['display_name']?.toString() ?? '',
              firstName: m['first_name']?.toString() ?? '',
              tier: m['tier']?.toString() ?? '',
              isOrganiser: m['is_organiser'] == true,
            ),
          )
          .toList(),
      relationships: (json['relationships'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (r) => PetRelationship(
              id: r['id']?.toString() ?? '',
              petId: r['pet_id']?.toString() ?? '',
              contactId: r['contact_id']?.toString() ?? '',
              relationshipKind: RelationshipKind.fromWire(
                r['relationship_kind']?.toString(),
              ),
              isPrimary: r['is_primary'] == true,
              active: r['active'] != false,
              contactKind: r['contact_kind']?.toString() ?? '',
              contactName: r['contact_name']?.toString() ?? '',
              contactPhone: r['contact_phone']?.toString(),
              contactInactiveAt: r['contact_inactive_at'] != null
                  ? DateTime.tryParse(r['contact_inactive_at'].toString())
                  : null,
            ),
          )
          .toList(),
    );
  }
}
