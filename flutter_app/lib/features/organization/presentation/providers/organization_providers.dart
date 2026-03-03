import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/organization_remote_datasource.dart';
import '../../domain/entities/archived_pet.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/organization_member.dart';
import '../../../pet_profile/domain/entities/pet.dart';

final orgRemoteDataSourceProvider = Provider<OrganizationRemoteDataSource>((ref) {
  return OrganizationRemoteDataSource();
});

final _orgTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).accessToken;
});

class OrganizationListNotifier extends AsyncNotifier<List<Organization>> {
  @override
  Future<List<Organization>> build() async {
    final token = ref.watch(_orgTokenProvider);
    if (token == null) return [];
    final ds = ref.read(orgRemoteDataSourceProvider);
    return ds.getOrganizations(token);
  }

  Future<Organization> createOrganization(Map<String, dynamic> data) async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    final org = await ds.createOrganization(data, token);
    ref.invalidateSelf();
    return org;
  }

  Future<void> updateOrganization(int orgId, Map<String, dynamic> data) async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    await ds.updateOrganization(orgId, data, token);
    ref.invalidateSelf();
  }

  Future<void> deleteOrganization(int orgId) async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    await ds.deleteOrganization(orgId, token);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final organizationListProvider =
    AsyncNotifierProvider<OrganizationListNotifier, List<Organization>>(
        OrganizationListNotifier.new);

class OrgMembersNotifier extends FamilyAsyncNotifier<List<OrganizationMember>, int> {
  @override
  Future<List<OrganizationMember>> build(int orgId) async {
    final token = ref.watch(_orgTokenProvider);
    if (token == null) return [];
    final ds = ref.read(orgRemoteDataSourceProvider);
    return ds.getMembers(orgId, token);
  }

  Future<String> createInvite() async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    return ds.inviteMember(arg, token);
  }

  Future<void> updateMemberRole(int userId, String role) async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    await ds.updateMemberRole(arg, userId, role, token);
    ref.invalidateSelf();
  }

  Future<void> removeMember(int userId) async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    await ds.removeMember(arg, userId, token);
    ref.invalidateSelf();
  }

  Future<void> leaveOrganization() async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    await ds.leaveOrganization(arg, token);
  }
}

final orgMembersProvider =
    AsyncNotifierProvider.family<OrgMembersNotifier, List<OrganizationMember>, int>(
        OrgMembersNotifier.new);

class OrgPetsNotifier extends FamilyAsyncNotifier<List<Pet>, int> {
  @override
  Future<List<Pet>> build(int orgId) async {
    final token = ref.watch(_orgTokenProvider);
    if (token == null) return [];
    final ds = ref.read(orgRemoteDataSourceProvider);
    final models = await ds.getOrganizationPets(orgId, token);
    return models.map((m) => Pet(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      species: m['species']?.toString() ?? '',
      breed: m['breed']?.toString() ?? '',
      dateOfBirth: m['date_of_birth'] != null || m['dateOfBirth'] != null
          ? DateTime.tryParse((m['date_of_birth'] ?? m['dateOfBirth']).toString())
          : null,
      weight: (m['weight'] as num?)?.toDouble(),
      gender: m['gender']?.toString() ?? '',
      bio: m['bio']?.toString() ?? '',
      insurance: m['insurance']?.toString() ?? '',
      chipId: m['chipId']?.toString() ?? m['chip_id']?.toString() ?? '',
      colorValue: m['colorValue'] as int? ?? m['color_value'] as int?,
      passedAway: m['passedAway'] == true || m['passed_away'] == true,
      photoPath: m['photoPath']?.toString() ?? m['photo_path']?.toString(),
      vetId: m['vetId']?.toString() ?? m['vet_id']?.toString(),
    )).toList();
  }

  Future<void> createPet(Map<String, dynamic> petData) async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    await ds.createOrganizationPet(arg, petData, token);
    ref.invalidateSelf();
  }

  Future<void> transferPet(String petId, {
    required String recipientEmail,
    String transferType = 'adoption',
    String notes = '',
  }) async {
    final token = ref.read(_orgTokenProvider)!;
    final ds = ref.read(orgRemoteDataSourceProvider);
    await ds.transferPetToUser(arg, petId,
        recipientEmail: recipientEmail, transferType: transferType,
        notes: notes, token: token);
    ref.invalidateSelf();
  }
}

final orgPetsProvider =
    AsyncNotifierProvider.family<OrgPetsNotifier, List<Pet>, int>(
        OrgPetsNotifier.new);

class OrgArchivedPetsNotifier extends FamilyAsyncNotifier<List<ArchivedPet>, int> {
  @override
  Future<List<ArchivedPet>> build(int orgId) async {
    final token = ref.watch(_orgTokenProvider);
    if (token == null) return [];
    final ds = ref.read(orgRemoteDataSourceProvider);
    return ds.getOrganizationArchivedPets(orgId, token);
  }
}

final orgArchivedPetsProvider =
    AsyncNotifierProvider.family<OrgArchivedPetsNotifier, List<ArchivedPet>, int>(
        OrgArchivedPetsNotifier.new);

class UserArchivedPetsNotifier extends AsyncNotifier<List<ArchivedPet>> {
  @override
  Future<List<ArchivedPet>> build() async {
    final token = ref.watch(_orgTokenProvider);
    if (token == null) return [];
    final ds = ref.read(orgRemoteDataSourceProvider);
    return ds.getUserArchivedPets(token);
  }
}

final userArchivedPetsProvider =
    AsyncNotifierProvider<UserArchivedPetsNotifier, List<ArchivedPet>>(
        UserArchivedPetsNotifier.new);

final isOrgSuperUserProvider = Provider.family<bool, int>((ref, orgId) {
  final orgsAsync = ref.watch(organizationListProvider);
  return orgsAsync.whenOrNull(data: (orgs) {
    final org = orgs.where((o) => o.id == orgId).firstOrNull;
    return org?.isSuperUser ?? false;
  }) ?? false;
});
