import '../domain/entities/contact_detail.dart';
import '../domain/entities/contact_summary.dart';
import '../domain/entities/pet_people.dart';
import '../domain/entities/related_care.dart';
import '../domain/entities/roster.dart';
import '../domain/repositories/people_repository.dart';
import 'dto/people_dtos.dart';
import 'people_api.dart';

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
  Future<ContactDetail> patchContact(String id, Map<String, dynamic> patch) async {
    final json = await _api.patchJson('/api/people/contacts/$id', patch);
    return ContactDetailDto.fromJson(json);
  }

  @override
  Future<void> deleteContact(String id) async {
    await _api.delete('/api/people/contacts/$id');
  }

  @override
  Future<String?> contactIdForLegacyVet(String vetId) async {
    final json = await _api.getJson('/api/people/contacts/by-legacy-vet/$vetId');
    return json['id']?.toString();
  }
}
