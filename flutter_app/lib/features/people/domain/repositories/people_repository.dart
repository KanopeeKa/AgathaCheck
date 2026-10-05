import '../entities/contact_detail.dart';
import '../entities/contact_summary.dart';
import '../entities/household.dart';
import '../entities/pet_people.dart';
import '../entities/related_care.dart';
import '../entities/roster.dart';
import '../enums/relationship_kind.dart';

abstract class PeopleRepository {
  Future<Roster> fetchRoster({bool includeInactive = false});

  Future<List<ContactSummary>> listContactSummaries({
    bool includeInactive = false,
  });

  Future<ContactDetail> fetchContactDetail(String id);

  Future<RelatedCare> fetchRelatedCare(String id);

  Future<PetPeople> fetchPetPeople(String petId);

  Future<ContactDetail> createContact(Map<String, dynamic> body);

  Future<ContactDetail> patchContact(String id, Map<String, dynamic> patch);

  Future<void> deleteContact(String id);

  Future<void> addContactPetRelationship({
    required String petId,
    required String contactId,
    required RelationshipKind relationshipKind,
  });

  Future<List<PetRelationship>> fetchPetRelationships(String petId);

  Future<List<PetRelationship>> setPetRelationshipSlot({
    required String petId,
    required RelationshipKind slotKind,
    required String? contactId,
  });

  Future<List<PetRelationship>> removePetRelationship({
    required String petId,
    required String relationshipId,
  });

  Future<List<PetRelationship>> replacePetRelationships(
    String petId,
    List<Map<String, dynamic>> relationships,
  );

  Future<String?> contactIdForLegacyVet(String vetId);
}

class HouseholdMemberRemovalPreview {
  const HouseholdMemberRemovalPreview({
    required this.remainingAccess,
    required this.requiresSuccessor,
  });

  final List<HouseholdRemainingAccess> remainingAccess;
  final bool requiresSuccessor;
}

class HouseholdRemainingAccess {
  const HouseholdRemainingAccess({
    required this.petId,
    required this.petName,
    required this.source,
    this.role,
    this.until,
  });

  final String petId;
  final String petName;
  final String source;
  final String? role;
  final String? until;
}

abstract class HouseholdsRepository {
  Future<List<Household>> listHouseholds();

  Future<Household> createHousehold(String name);

  Future<void> createHouseholdInvite({
    required String householdId,
    required String inviteeEmail,
    required String contactId,
    String accessTier = 'full_access',
  });

  Future<void> revokeHouseholdInvite({
    required String householdId,
    required String inviteId,
  });

  Future<HouseholdMemberRemovalPreview> fetchMemberRemovalPreview({
    required String householdId,
    required String memberUserId,
  });

  Future<void> removeHouseholdMember({
    required String householdId,
    required String memberUserId,
    bool removeAllAccessToMyPets,
    String? successorUserId,
  });
}
