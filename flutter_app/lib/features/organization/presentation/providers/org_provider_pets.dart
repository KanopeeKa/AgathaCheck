import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/archived_pet.dart';
import 'org_provider_deps.dart';
import 'org_provider_list.dart';

class OrgPetsNotifier extends FamilyAsyncNotifier<List<Pet>, String> {
  @override
  Future<List<Pet>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    final models = await repo.getOrganizationPets(orgId, token);
    return models
        .map(
          (m) => Pet(
            id: m['id']?.toString() ?? '',
            name: m['name']?.toString() ?? '',
            species: m['species']?.toString() ?? '',
            breed: m['breed']?.toString() ?? '',
            dateOfBirth: parseCalendarDate(
              m['date_of_birth'] ?? m['dateOfBirth'],
            ),
            weight: (m['weight'] as num?)?.toDouble(),
            gender: m['gender']?.toString() ?? '',
            bio: m['bio']?.toString() ?? '',
            insurance: m['insurance']?.toString() ?? '',
            chipId: m['chipId']?.toString() ?? m['chip_id']?.toString() ?? '',
            colorValue: m['colorValue'] as int? ?? m['color_value'] as int?,
            passedAway: m['passedAway'] == true || m['passed_away'] == true,
            photoPath:
                m['photoPath']?.toString() ?? m['photo_path']?.toString(),
            vetId: m['vetId']?.toString() ?? m['vet_id']?.toString(),
            organizationId: m['organization_id']?.toString(),
            organizationName: m['organization_name']?.toString(),
          ),
        )
        .toList();
  }

  Future<void> createPet(Map<String, dynamic> petData) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.createOrganizationPet(arg, petData, token);
    ref.invalidateSelf();
  }

  Future<void> transferPet(
    String petId, {
    required String recipientEmail,
    String transferType = 'adoption',
    String notes = '',
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.transferPetToUser(
      arg,
      petId,
      recipientEmail: recipientEmail,
      transferType: transferType,
      notes: notes,
      token: token,
    );
    ref.invalidateSelf();
  }
}

final orgPetsProvider =
    AsyncNotifierProvider.family<OrgPetsNotifier, List<Pet>, String>(
      OrgPetsNotifier.new,
    );

class OrgArchivedPetsNotifier
    extends FamilyAsyncNotifier<List<ArchivedPet>, String> {
  @override
  Future<List<ArchivedPet>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getOrganizationArchivedPets(orgId, token);
  }
}

final orgArchivedPetsProvider =
    AsyncNotifierProvider.family<
      OrgArchivedPetsNotifier,
      List<ArchivedPet>,
      String
    >(OrgArchivedPetsNotifier.new);

class UserArchivedPetsNotifier extends AsyncNotifier<List<ArchivedPet>> {
  @override
  Future<List<ArchivedPet>> build() async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getUserArchivedPets(token);
  }
}

final userArchivedPetsProvider =
    AsyncNotifierProvider<UserArchivedPetsNotifier, List<ArchivedPet>>(
      UserArchivedPetsNotifier.new,
    );

final isOrgSuperUserProvider = Provider.family<bool, String>((ref, orgId) {
  final orgsAsync = ref.watch(organizationListProvider);
  return orgsAsync.whenOrNull(
        data: (orgs) {
          final org = orgs.where((o) => o.id == orgId).firstOrNull;
          return org?.isSuperUser ?? false;
        },
      ) ??
      false;
});

final isOrgAdminProvider = Provider.family<bool, String>((ref, orgId) {
  final orgsAsync = ref.watch(organizationListProvider);
  return orgsAsync.whenOrNull(
        data: (orgs) {
          final org = orgs.where((o) => o.id == orgId).firstOrNull;
          return org?.isOrgAdmin ?? false;
        },
      ) ??
      false;
});

final isOrgFosterProvider = Provider.family<bool, String>((ref, orgId) {
  final orgsAsync = ref.watch(organizationListProvider);
  return orgsAsync.whenOrNull(
        data: (orgs) {
          final org = orgs.where((o) => o.id == orgId).firstOrNull;
          return org?.isFoster ?? false;
        },
      ) ??
      false;
});
