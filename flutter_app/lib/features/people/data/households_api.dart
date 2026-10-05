import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/household.dart';
import '../domain/entities/household_invite_preview.dart';
import '../domain/repositories/people_repository.dart';
import 'dto/people_dtos.dart';

class HouseholdsApi {
  HouseholdsApi({required this.baseUrl, required this.client, this.token});

  final String baseUrl;
  final http.Client client;
  final String? token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<Household> createHousehold(
    String name, {
    List<String> petIds = const [],
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/households'),
      headers: _headers,
      body: json.encode({
        'name': name,
        if (petIds.isNotEmpty) 'pet_ids': petIds,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Create household ${response.statusCode}');
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    return HouseholdDto.fromJson(decoded);
  }

  Future<Household> fetchHouseholdDetail(String householdId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/households/$householdId'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception('Household detail ${response.statusCode}');
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    return HouseholdDto.fromJson(decoded);
  }

  Future<Household> renameHousehold({
    required String householdId,
    required String name,
  }) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/api/households/$householdId'),
      headers: _headers,
      body: json.encode({'name': name}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Rename household ${response.statusCode}');
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final household = decoded['household'] as Map<String, dynamic>? ?? decoded;
    return HouseholdDto.fromJson(household);
  }

  Future<void> setHouseholdPets({
    required String householdId,
    required List<String> petIds,
  }) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/households/$householdId/pets'),
      headers: _headers,
      body: json.encode({'pet_ids': petIds}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Set household pets ${response.statusCode}');
    }
  }

  Future<void> createInvite({
    required String householdId,
    required String inviteeEmail,
    String? contactId,
    String accessTier = 'full_access',
    bool isOrganiser = false,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/households/$householdId/invites'),
      headers: _headers,
      body: json.encode({
        'invitee_email': inviteeEmail,
        'access_tier': accessTier,
        if (contactId != null && contactId.isNotEmpty) 'contact_id': contactId,
        if (isOrganiser) 'is_organiser': true,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Create household invite ${response.statusCode}');
    }
  }

  Future<List<Household>> listHouseholds() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/households'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception('Households API ${response.statusCode}');
    }
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      final list = decoded['households'] as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(HouseholdDto.fromJson)
          .toList();
    }
    return const [];
  }

  Future<void> revokeInvite({
    required String householdId,
    required String inviteId,
  }) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/households/$householdId/invites/$inviteId'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception('Revoke invite ${response.statusCode}');
    }
  }

  Future<HouseholdMemberRemovalPreview> fetchMemberRemovalPreview({
    required String householdId,
    required String memberUserId,
  }) async {
    final response = await client.get(
      Uri.parse(
        '$baseUrl/api/households/$householdId/members/$memberUserId/removal-preview',
      ),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception('Removal preview ${response.statusCode}');
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final remainingRaw = decoded['remaining_access'] as List? ?? [];
    final remaining = remainingRaw.whereType<Map<String, dynamic>>().map((row) {
      return HouseholdRemainingAccess(
        petId: row['pet_id']?.toString() ?? '',
        petName: row['pet_name']?.toString() ?? '',
        source: row['source']?.toString() ?? '',
        role: row['role']?.toString(),
        until: row['until']?.toString(),
      );
    }).toList();
    return HouseholdMemberRemovalPreview(
      remainingAccess: remaining,
      requiresSuccessor: decoded['requires_successor'] == true,
    );
  }

  Future<void> removeMember({
    required String householdId,
    required String memberUserId,
    bool removeAllAccessToMyPets = false,
    String? successorUserId,
  }) async {
    final body = <String, dynamic>{
      if (removeAllAccessToMyPets) 'remove_all_access_to_my_pets': true,
      if (successorUserId != null) 'successor_user_id': successorUserId,
    };
    final response = await client.delete(
      Uri.parse('$baseUrl/api/households/$householdId/members/$memberUserId'),
      headers: _headers,
      body: json.encode(body),
    );
    if (response.statusCode >= 400) {
      throw Exception('Remove member ${response.statusCode}');
    }
  }

  Future<HouseholdInvitePreview> fetchInvitePreview(String code) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/households/invites/code/$code'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception('Household invite preview ${response.statusCode}');
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    return HouseholdInvitePreview(
      inviteId: decoded['invite_id']?.toString() ?? '',
      code: decoded['code']?.toString() ?? code,
      householdId: decoded['household_id']?.toString() ?? '',
      householdName: decoded['household_name']?.toString() ?? '',
      inviterName: decoded['inviter_name']?.toString() ?? '',
      accessTier: decoded['access_tier']?.toString() ?? 'full_access',
      isOrganiser: decoded['is_organiser'] == true,
      inviteeEmail: decoded['invitee_email']?.toString() ?? '',
    );
  }

  Future<void> acceptInvite(String code) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/households/invites/code/$code/accept'),
      headers: _headers,
      body: json.encode({}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Accept household invite ${response.statusCode}');
    }
  }

  Future<void> declineInvite(String code) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/households/invites/code/$code/decline'),
      headers: _headers,
      body: json.encode({}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Decline household invite ${response.statusCode}');
    }
  }
}

class HouseholdsRepositoryImpl implements HouseholdsRepository {
  HouseholdsRepositoryImpl(this._api);

  final HouseholdsApi _api;

  @override
  Future<List<Household>> listHouseholds() => _api.listHouseholds();

  @override
  Future<Household> fetchHouseholdDetail(String householdId) =>
      _api.fetchHouseholdDetail(householdId);

  @override
  Future<Household> createHousehold(
    String name, {
    List<String> petIds = const [],
  }) => _api.createHousehold(name, petIds: petIds);

  @override
  Future<Household> renameHousehold({
    required String householdId,
    required String name,
  }) => _api.renameHousehold(householdId: householdId, name: name);

  @override
  Future<void> setHouseholdPets({
    required String householdId,
    required List<String> petIds,
  }) => _api.setHouseholdPets(householdId: householdId, petIds: petIds);

  @override
  Future<void> createHouseholdInvite({
    required String householdId,
    required String inviteeEmail,
    String? contactId,
    String accessTier = 'full_access',
    bool isOrganiser = false,
  }) => _api.createInvite(
    householdId: householdId,
    inviteeEmail: inviteeEmail,
    contactId: contactId,
    accessTier: accessTier,
    isOrganiser: isOrganiser,
  );

  @override
  Future<void> revokeHouseholdInvite({
    required String householdId,
    required String inviteId,
  }) => _api.revokeInvite(householdId: householdId, inviteId: inviteId);

  @override
  Future<HouseholdMemberRemovalPreview> fetchMemberRemovalPreview({
    required String householdId,
    required String memberUserId,
  }) => _api.fetchMemberRemovalPreview(
    householdId: householdId,
    memberUserId: memberUserId,
  );

  @override
  Future<void> removeHouseholdMember({
    required String householdId,
    required String memberUserId,
    bool removeAllAccessToMyPets = false,
    String? successorUserId,
  }) => _api.removeMember(
    householdId: householdId,
    memberUserId: memberUserId,
    removeAllAccessToMyPets: removeAllAccessToMyPets,
    successorUserId: successorUserId,
  );

  @override
  Future<HouseholdInvitePreview> fetchHouseholdInvitePreview(String code) =>
      _api.fetchInvitePreview(code);

  @override
  Future<void> acceptHouseholdInvite(String code) => _api.acceptInvite(code);

  @override
  Future<void> declineHouseholdInvite(String code) => _api.declineInvite(code);
}
