import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/archived_pet.dart';
import '../../domain/entities/foster_placement.dart';
import '../models/org_pet_list_entry.dart';
import '../utils/org_pets_care_utils.dart';
import 'org_provider_deps.dart';
import 'org_provider_pets.dart';

final orgPetsTabProvider = StateProvider.family<OrgPetsTab, String>(
  (ref, orgId) => OrgPetsTab.needAttention,
);

final orgPetsFilterProvider = StateProvider.family<OrgPetsFilterState, String>(
  (ref, orgId) => const OrgPetsFilterState(),
);

class OrgPlacementsNotifier extends FamilyAsyncNotifier<List<FosterPlacement>, String> {
  @override
  Future<List<FosterPlacement>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getOrganizationPlacements(orgId, token);
  }
}

final orgPlacementsProvider =
    AsyncNotifierProvider.family<OrgPlacementsNotifier, List<FosterPlacement>, String>(
      OrgPlacementsNotifier.new,
    );

class OrgPetsScreenData {
  const OrgPetsScreenData({
    required this.entries,
    required this.filteredEntries,
    required this.placements,
  });

  final List<OrgPetListEntry> entries;
  final List<OrgPetListEntry> filteredEntries;
  final List<FosterPlacement> placements;
}

final orgPetsScreenDataProvider =
    Provider.family<AsyncValue<OrgPetsScreenData>, String>((ref, orgId) {
      final petsAsync = ref.watch(orgPetsProvider(orgId));
      final placementsAsync = ref.watch(orgPlacementsProvider(orgId));
      final archivedAsync = ref.watch(orgArchivedPetsProvider(orgId));
      final tab = ref.watch(orgPetsTabProvider(orgId));
      final filters = ref.watch(orgPetsFilterProvider(orgId));

      return petsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (pets) {
          return placementsAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (e, st) => AsyncValue.error(e, st),
            data: (placements) {
              return archivedAsync.when(
                loading: () => const AsyncValue.loading(),
                error: (e, st) => AsyncValue.error(e, st),
                data: (archived) {
                  final fosterEndDates = {
                    for (final pet in pets)
                      if (pet.fosterEndDate != null) pet.id: pet.fosterEndDate,
                  };
                  final entries = buildOrgPetEntries(
                    pets: pets,
                    placements: placements,
                    archivedPets: archived,
                    fosterEndDates: fosterEndDates,
                  );
                  final filtered = filterOrgPetEntries(
                    entries: entries,
                    tab: tab,
                    filters: filters,
                    placements: placements,
                  );
                  return AsyncValue.data(
                    OrgPetsScreenData(
                      entries: entries,
                      filteredEntries: filtered,
                      placements: placements,
                    ),
                  );
                },
              );
            },
          );
        },
      );
    });
