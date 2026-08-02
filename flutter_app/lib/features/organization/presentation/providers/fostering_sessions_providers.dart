import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/foster_placement.dart';
import 'org_provider_deps.dart';

typedef FosteringSessionsFilters = Map<String, String>;

final fosteringSessionsFiltersProvider =
    StateProvider.family<FosteringSessionsFilters, String>((ref, orgId) => {});

final fosteringSessionsListProvider =
    FutureProvider.family<List<FosterPlacement>, String>((ref, orgId) async {
      final token = ref.watch(orgTokenProvider);
      if (token == null) return [];
      final filters = ref.watch(fosteringSessionsFiltersProvider(orgId));
      final repo = ref.read(organizationRepositoryProvider);
      return repo.getOrganizationPlacements(
        orgId,
        token,
        filters: filters.isEmpty ? null : filters,
      );
    });
