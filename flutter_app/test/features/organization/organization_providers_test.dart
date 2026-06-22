import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/archived_pet.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/repositories/organization_repository.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';

import '../../helpers/fakes.dart';

/// Records calls so we can assert what the notifiers delegated to the repository.
class RecordingOrganizationRepository implements OrganizationRepository {
  final List<Organization> created = [];
  final List<Organization> updated = [];
  final List<String> deleted = [];
  final List<(String, String, OrgMemberRole)> roleChanges = [];

  @override
  Future<List<Organization>> getOrganizations(String token) async => [
        const Organization(id: 'org-1', name: 'Clinic', type: OrganizationType.charity),
      ];

  @override
  Future<Organization> createOrganization(Organization org, String token) async {
    created.add(org);
    return org;
  }

  @override
  Future<Organization> updateOrganization(Organization org, String token) async {
    updated.add(org);
    return org;
  }

  @override
  Future<void> deleteOrganization(String id, String token) async {
    deleted.add(id);
  }

  @override
  Future<void> updateMemberRole(
      String orgId, String userId, OrgMemberRole role, String token) async {
    roleChanges.add((orgId, userId, role));
  }

  // --- Unused-by-these-tests members: sensible defaults ---
  @override
  Future<Organization> getOrganization(String id, String token) async =>
      const Organization(id: 'x', name: 'x', type: OrganizationType.professional);
  @override
  Future<Organization> uploadPhoto(
          String id, Uint8List bytes, String filename, String token) async =>
      const Organization(id: 'x', name: 'x', type: OrganizationType.professional);
  @override
  Future<List<OrganizationMember>> getMembers(String orgId, String token) async => [];
  @override
  Future<String> inviteMember(String orgId, String token) async => 'code';
  @override
  Future<Map<String, dynamic>> inviteByEmail(
          String orgId, String email, String role, String token) async =>
      {'success': true};
  @override
  Future<void> joinOrganization(String code, String token) async {}
  @override
  Future<void> removeMember(String orgId, String userId, String token) async {}
  @override
  Future<void> leaveOrganization(String orgId, String token) async {}
  @override
  Future<List<Map<String, dynamic>>> getPendingInvites(String token) async => [];
  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId, String token) async =>
      {'organization_id': 'org-1'};
  @override
  Future<void> declineInvite(String inviteId, String token) async {}
  @override
  Future<List<Map<String, dynamic>>> getOrganizationPets(
          String orgId, String token) async =>
      [];
  @override
  Future<Map<String, dynamic>> createOrganizationPet(
          String orgId, Map<String, dynamic> petJson, String token) async =>
      {};
  @override
  Future<void> transferPetToUser(String orgId, String petId,
      {required String recipientEmail,
      String transferType = 'adoption',
      String notes = '',
      required String token}) async {}
  @override
  Future<void> transferPetToOrg(String petId, String orgId,
      {String notes = '', required String token}) async {}
  @override
  Future<List<ArchivedPet>> getOrganizationArchivedPets(
          String orgId, String token) async =>
      [];
  @override
  Future<List<ArchivedPet>> getUserArchivedPets(String token) async => [];
  @override
  Future<List<Map<String, dynamic>>> getFamilyEvents(
          String token, String petId) async =>
      [];
  @override
  Future<Map<String, dynamic>> createFamilyEvent(
          String token, String petId, Map<String, dynamic> body) async =>
      {};
  @override
  Future<void> updateFamilyEvent(String token, String petId, String eventId,
      Map<String, dynamic> body) async {}
  @override
  Future<void> deleteFamilyEvent(
      String token, String petId, String eventId) async {}
}

ProviderContainer makeContainer(RecordingOrganizationRepository repo) {
  return ProviderContainer(overrides: [
    authProvider.overrideWith((ref) => FakeAuthNotifier()),
    organizationRepositoryProvider.overrideWithValue(repo),
  ]);
}

void main() {
  test('organizationListProvider reads through the repository', () async {
    final repo = RecordingOrganizationRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    final orgs = await container.read(organizationListProvider.future);
    expect(orgs, hasLength(1));
    expect(orgs.single.name, 'Clinic');
  });

  test('createOrganization converts the form map to a domain entity', () async {
    final repo = RecordingOrganizationRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    await container.read(organizationListProvider.future);
    await container.read(organizationListProvider.notifier).createOrganization(
        {'name': 'New Clinic', 'type': 'charity'});

    expect(repo.created, hasLength(1));
    expect(repo.created.single.name, 'New Clinic');
    expect(repo.created.single.type, OrganizationType.charity);
  });

  test('updateMemberRole maps the role string to the domain enum', () async {
    final repo = RecordingOrganizationRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    await container.read(orgMembersProvider('org-1').future);
    await container
        .read(orgMembersProvider('org-1').notifier)
        .updateMemberRole('user-9', 'super_user');

    expect(repo.roleChanges, hasLength(1));
    expect(repo.roleChanges.single.$1, 'org-1');
    expect(repo.roleChanges.single.$2, 'user-9');
    expect(repo.roleChanges.single.$3, OrgMemberRole.superUser);
  });
}
