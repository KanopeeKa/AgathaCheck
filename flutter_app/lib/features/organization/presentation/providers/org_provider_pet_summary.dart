import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import 'org_provider_deps.dart';

Pet orgSummaryPetFromJson(Map<String, dynamic> m) {
  return Pet(
    id: m['id']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    species: m['species']?.toString() ?? '',
    breed: m['breed']?.toString() ?? '',
    photoPath: m['photo_path']?.toString() ?? m['photoPath']?.toString(),
    organizationId: m['organization_id']?.toString(),
    dateOfBirth: parseCalendarDate(m['date_of_birth'] ?? m['dateOfBirth']),
  );
}

Pet orgRedactedPetFromJson(Map<String, dynamic> m) {
  return Pet(
    id: m['id']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    species: m['species']?.toString() ?? '',
    breed: m['breed']?.toString() ?? '',
    photoPath: m['photo_path']?.toString() ?? m['photoPath']?.toString(),
    organizationId: m['organization_id']?.toString(),
    dateOfBirth: parseCalendarDate(m['date_of_birth'] ?? m['dateOfBirth']),
  );
}

class OrgPetSummaryNotifier extends FamilyAsyncNotifier<List<Pet>, String> {
  @override
  Future<List<Pet>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    final models = await repo.getOrganizationPetSummary(orgId, token);
    return models.map(orgSummaryPetFromJson).toList();
  }
}

final orgPetSummaryProvider =
    AsyncNotifierProvider.family<OrgPetSummaryNotifier, List<Pet>, String>(
      OrgPetSummaryNotifier.new,
    );

typedef OrgRedactedPetKey = ({String orgId, String petId});

class OrgRedactedPetNotifier
    extends FamilyAsyncNotifier<Pet, OrgRedactedPetKey> {
  @override
  Future<Pet> build(OrgRedactedPetKey key) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final repo = ref.read(organizationRepositoryProvider);
    final model = await repo.getRedactedOrganizationPet(
      key.orgId,
      key.petId,
      token,
    );
    return orgRedactedPetFromJson(model);
  }
}

final orgRedactedPetProvider =
    AsyncNotifierProvider.family<
      OrgRedactedPetNotifier,
      Pet,
      OrgRedactedPetKey
    >(OrgRedactedPetNotifier.new);
