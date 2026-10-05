import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/household.dart';
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
}

class HouseholdsRepositoryImpl implements HouseholdsRepository {
  HouseholdsRepositoryImpl(this._api);

  final HouseholdsApi _api;

  @override
  Future<List<Household>> listHouseholds() => _api.listHouseholds();

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
}
