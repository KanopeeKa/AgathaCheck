import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/datasources/foster_placements_remote_datasource.dart';
import '../../domain/entities/foster_placement.dart';
import 'organization_providers.dart';

final fosterPlacementsDataSourceProvider =
    Provider<FosterPlacementsRemoteDataSource>((ref) {
  return FosterPlacementsRemoteDataSource(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(authHttpClientProvider),
  );
});

class PendingFosterPlacementsNotifier
    extends AsyncNotifier<List<FosterPlacement>> {
  @override
  Future<List<FosterPlacement>> build() async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return [];
    final dataSource = ref.read(fosterPlacementsDataSourceProvider);
    final rows = await dataSource.getPendingPlacements(token);
    return rows.map(FosterPlacement.fromJson).toList();
  }

  Future<void> accept(String placementId) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final dataSource = ref.read(fosterPlacementsDataSourceProvider);
    await dataSource.acceptPlacement(placementId, token);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
    await ref.read(allPetsIncludingOrgProvider.future);
  }

  Future<void> decline(String placementId) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final dataSource = ref.read(fosterPlacementsDataSourceProvider);
    await dataSource.declinePlacement(placementId, token);
    ref.invalidateSelf();
  }
}

final pendingFosterPlacementsProvider =
    AsyncNotifierProvider<PendingFosterPlacementsNotifier, List<FosterPlacement>>(
        PendingFosterPlacementsNotifier.new);

class PendingAdoptionPlacementsNotifier
    extends AsyncNotifier<List<FosterPlacement>> {
  @override
  Future<List<FosterPlacement>> build() async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return [];
    final dataSource = ref.read(fosterPlacementsDataSourceProvider);
    final rows = await dataSource.getPendingAdoptions(token);
    return rows.map(FosterPlacement.fromJson).toList();
  }

  Future<void> confirm(String placementId) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final dataSource = ref.read(fosterPlacementsDataSourceProvider);
    await dataSource.confirmAdoption(placementId, token);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
    await ref.read(allPetsIncludingOrgProvider.future);
  }
}

final pendingAdoptionPlacementsProvider =
    AsyncNotifierProvider<PendingAdoptionPlacementsNotifier, List<FosterPlacement>>(
        PendingAdoptionPlacementsNotifier.new);

class PetFosterPlacementNotifier
    extends FamilyAsyncNotifier<PetFosterPlacementState, (String, String)> {
  @override
  Future<PetFosterPlacementState> build((String, String) arg) async {
    final (orgId, petId) = arg;
    final token = ref.watch(authProvider).accessToken;
    if (token == null) {
      return const PetFosterPlacementState(status: 'not_in_foster');
    }
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getPetPlacement(orgId, petId, token);
  }

  Future<void> startPlacement({
    required String fosterUserId,
    DateTime? startDate,
    String notes = '',
  }) async {
    final (orgId, petId) = arg;
    final token = ref.read(authProvider).accessToken;
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.startFosterPlacement(
      orgId,
      petId,
      fosterUserId: fosterUserId,
      startDate: startDate,
      notes: notes,
      token: token,
    );
    ref.invalidateSelf();
  }

  Future<void> endPlacement(String placementId, {DateTime? endDate}) async {
    final (orgId, _) = arg;
    final token = ref.read(authProvider).accessToken;
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.endFosterPlacement(
      orgId,
      placementId,
      endDate: endDate,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
  }

  Future<void> startAdoption(
    String placementId, {
    String adoptionConditions = '',
  }) async {
    final (orgId, _) = arg;
    final token = ref.read(authProvider).accessToken;
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.startAdoption(
      orgId,
      placementId,
      adoptionConditions: adoptionConditions,
      token: token,
    );
    ref.invalidateSelf();
  }

  Future<void> completeAdoptionConditions(String placementId) async {
    final (orgId, _) = arg;
    final token = ref.read(authProvider).accessToken;
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.completeAdoptionConditions(orgId, placementId, token: token);
    ref.invalidateSelf();
  }

  Future<void> cancelAdoption(String placementId) async {
    final (orgId, _) = arg;
    final token = ref.read(authProvider).accessToken;
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.cancelAdoption(orgId, placementId, token: token);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
  }

  Future<void> directAdopt({
    required String fosterUserId,
    String adoptionConditions = '',
    String notes = '',
  }) async {
    final (orgId, petId) = arg;
    final token = ref.read(authProvider).accessToken;
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.directAdopt(
      orgId,
      petId,
      fosterUserId: fosterUserId,
      adoptionConditions: adoptionConditions,
      notes: notes,
      token: token,
    );
    ref.invalidateSelf();
  }
}

final petFosterPlacementProvider = AsyncNotifierProvider.family<
    PetFosterPlacementNotifier,
    PetFosterPlacementState,
    (String, String)>(PetFosterPlacementNotifier.new);
