import 'dart:typed_data';

import 'package:pet_profile_app/features/organization/domain/entities/archived_pet.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/domain/entities/member_privacy_settings.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';

import 'recording_organization_repository_base.dart';

mixin RecordingOrganizationRepositoryCoreMixin
    on RecordingOrganizationRepositoryBase {
  @override
  Future<List<Organization>> getOrganizations(String token) async => [
    const Organization(
      id: 'org-1',
      name: 'Clinic',
      type: OrganizationType.charity,
    ),
  ];

  @override
  Future<Organization> createOrganization(
    Organization org,
    String token,
  ) async {
    created.add(org);
    return org;
  }

  @override
  Future<Organization> updateOrganization(
    Organization org,
    String token,
  ) async {
    updated.add(org);
    return org;
  }

  @override
  Future<void> deleteOrganization(String id, String token) async {
    deleted.add(id);
  }

  @override
  Future<void> updateMemberRole(
    String orgId,
    String userId,
    OrgMemberRole role,
    String token,
  ) async {
    roleChanges.add((orgId, userId, role));
  }

  @override
  Future<Organization> getOrganization(String id, String token) async =>
      const Organization(
        id: 'x',
        name: 'x',
        type: OrganizationType.professional,
      );

  @override
  Future<Organization> getPublicOrganization(
    String id, {
    String? token,
  }) async => const Organization(
    id: 'x',
    name: 'x',
    type: OrganizationType.professional,
  );

  @override
  Future<Organization> uploadPhoto(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  ) async => const Organization(
    id: 'x',
    name: 'x',
    type: OrganizationType.professional,
  );

  @override
  Future<Organization> uploadLogo(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  ) async => const Organization(
    id: 'x',
    name: 'x',
    type: OrganizationType.professional,
  );

  @override
  Future<List<OrganizationMember>> getMembers(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<Map<String, dynamic>> inviteByEmail(
    String orgId,
    String email,
    String role,
    String token,
  ) async => {'success': true};

  @override
  Future<void> removeMember(String orgId, String userId, String token) async {}

  @override
  Future<void> leaveOrganization(String orgId, String token) async {}

  @override
  Future<MemberPrivacySettings> getMemberPrivacy(
    String orgId,
    String token,
  ) async => const MemberPrivacySettings();

  @override
  Future<MemberPrivacySettings> updateMemberPrivacy(
    String orgId,
    MemberPrivacySettings settings,
    String token,
  ) async => settings;

  @override
  Future<List<Map<String, dynamic>>> getPendingInvites(String token) async =>
      [];

  @override
  Future<Map<String, dynamic>> acceptInvite(
    String inviteId,
    String token,
  ) async => {'organization_id': 'org-1'};

  @override
  Future<void> declineInvite(String inviteId, String token) async {}

  @override
  Future<List<Map<String, dynamic>>> getOrganizationPets(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<List<Map<String, dynamic>>> getOrganizationPetSummary(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<Map<String, dynamic>> getRedactedOrganizationPet(
    String orgId,
    String petId,
    String token,
  ) async => {};

  @override
  Future<Map<String, dynamic>> createOrganizationPet(
    String orgId,
    Map<String, dynamic> petJson,
    String token,
  ) async => {};

  @override
  Future<void> transferPetToUser(
    String orgId,
    String petId, {
    required String recipientEmail,
    String transferType = 'adoption',
    String notes = '',
    required String token,
  }) async {}

  @override
  Future<void> transferPetToOrg(
    String petId,
    String orgId, {
    String notes = '',
    required String token,
  }) async {}

  @override
  Future<List<ArchivedPet>> getOrganizationArchivedPets(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<List<ArchivedPet>> getUserArchivedPets(String token) async => [];

  @override
  Future<List<Map<String, dynamic>>> getFamilyEvents(
    String token,
    String petId,
  ) async => [];

  @override
  Future<Map<String, dynamic>> createFamilyEvent(
    String token,
    String petId,
    Map<String, dynamic> body,
  ) async => {};

  @override
  Future<void> updateFamilyEvent(
    String token,
    String petId,
    String eventId,
    Map<String, dynamic> body,
  ) async {}

  @override
  Future<void> deleteFamilyEvent(
    String token,
    String petId,
    String eventId,
  ) async {}
}
