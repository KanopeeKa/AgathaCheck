import '../domain/entities/contact_detail.dart';
import '../domain/entities/contact_summary.dart';
import '../domain/entities/pet_people.dart';
import '../domain/entities/related_care.dart';
import '../domain/entities/roster.dart';
import '../domain/enums/relationship_kind.dart';
import '../domain/repositories/people_repository.dart';
import 'dto/people_dtos.dart';
import 'people_api.dart';
import 'people_api_exception.dart';

class PeopleRepositoryImpl implements PeopleRepository {
  PeopleRepositoryImpl(this._api);

  final PeopleApi _api;

  @override
  Future<Roster> fetchRoster({bool includeInactive = false}) async {
    final json = await _api.getJson(
      '/api/people/roster',
      query: includeInactive ? {'include_inactive': 'true'} : null,
    );
    return RosterDto.fromJson(json);
  }

  @override
  Future<List<ContactSummary>> listContactSummaries({
    bool includeInactive = false,
  }) async {
    final list = await _api.getJsonList(
      '/api/people/contacts',
      query: includeInactive ? {'include_inactive': 'true'} : null,
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(ContactSummaryDto.fromJson)
        .toList();
  }

  @override
  Future<ContactDetail> fetchContactDetail(String id) async {
    final json = await _api.getJson('/api/people/contacts/$id');
    return ContactDetailDto.fromJson(json);
  }

  @override
  Future<RelatedCare> fetchRelatedCare(String id) async {
    final json = await _api.getJson('/api/people/contacts/$id/related');
    return RelatedCareDto.fromJson(json);
  }

  @override
  Future<PetPeople> fetchPetPeople(String petId) async {
    final json = await _api.getJson('/api/pets/$petId/people');
    return PetPeopleDto.fromJson(json);
  }

  @override
  Future<ContactDetail> createContact(Map<String, dynamic> body) async {
    final json = await _api.postJson('/api/people/contacts', body);
    return ContactDetailDto.fromJson(json);
  }

  @override
  Future<ContactDetail> patchContact(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final json = await _api.patchJson('/api/people/contacts/$id', patch);
    return ContactDetailDto.fromJson(json);
  }

  @override
  Future<void> deleteContact(String id) async {
    await _api.delete('/api/people/contacts/$id');
  }

  @override
  Future<void> addContactPetRelationship({
    required String petId,
    required String contactId,
    required RelationshipKind relationshipKind,
  }) async {
    await _api.postJson('/api/pets/$petId/people-relationships', {
      'contact_id': contactId,
      'relationship_kind': relationshipKind.wireValue,
    });
  }

  List<PetRelationship> _parseRelationshipList(List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map(_relationshipFromMap)
        .toList();
  }

  PetRelationship _relationshipFromMap(Map<String, dynamic> r) {
    final contact = r['contact'] as Map<String, dynamic>?;
    return PetRelationship(
      id: r['id']?.toString() ?? '',
      petId: r['pet_id']?.toString() ?? '',
      contactId: r['contact_id']?.toString() ?? '',
      relationshipKind: RelationshipKind.fromWire(
        r['relationship_kind']?.toString(),
      ),
      isPrimary: r['is_primary'] == true,
      active: r['active'] != false,
      contactKind:
          contact?['kind']?.toString() ?? r['contact_kind']?.toString() ?? '',
      contactName:
          contact?['name']?.toString() ?? r['contact_name']?.toString() ?? '',
      contactPhone:
          contact?['phone']?.toString() ?? r['contact_phone']?.toString(),
      contactInactiveAt: null,
    );
  }

  @override
  Future<List<PetRelationship>> fetchPetRelationships(String petId) async {
    final list = await _api.getJsonList(
      '/api/pets/$petId/people-relationships',
    );
    return _parseRelationshipList(list);
  }

  @override
  Future<List<PetRelationship>> setPetRelationshipSlot({
    required String petId,
    required RelationshipKind slotKind,
    required String? contactId,
  }) async {
    final list = await _api.putJsonList(
      '/api/pets/$petId/people-relationships/slots/${slotKind.wireValue}',
      contactId == null ? {} : {'contact_id': contactId},
    );
    return _parseRelationshipList(list);
  }

  @override
  Future<List<PetRelationship>> removePetRelationship({
    required String petId,
    required String relationshipId,
  }) async {
    final list = await _api.deleteJsonList(
      '/api/pets/$petId/people-relationships/$relationshipId',
    );
    return _parseRelationshipList(list);
  }

  @override
  Future<List<PetRelationship>> replacePetRelationships(
    String petId,
    List<Map<String, dynamic>> relationships,
  ) async {
    final list = await _api.putJsonList(
      '/api/pets/$petId/people-relationships',
      {'relationships': relationships},
    );
    return _parseRelationshipList(list);
  }

  @override
  Future<String?> contactIdForLegacyVet(String vetId) async {
    final json = await _api.getJson(
      '/api/people/contacts/by-legacy-vet/$vetId',
    );
    return json['id']?.toString();
  }
}
