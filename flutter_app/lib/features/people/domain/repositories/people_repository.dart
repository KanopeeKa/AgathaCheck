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

  Future<String?> contactIdForLegacyVet(String vetId);
}

abstract class HouseholdsRepository {
  Future<List<Household>> listHouseholds();
}
