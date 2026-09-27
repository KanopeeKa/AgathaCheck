import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/household_remote_datasource.dart';
import '../../data/repositories/household_repository_impl.dart';
import '../../domain/entities/household_summary.dart';
import '../../domain/repositories/household_repository.dart';

final householdDataSourceProvider = Provider<HouseholdRemoteDataSource>((ref) {
  return HouseholdRemoteDataSource(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(authHttpClientProvider),
  );
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepositoryImpl(ref.watch(householdDataSourceProvider));
});

final householdListProvider = FutureProvider<List<HouseholdSummary>>((
  ref,
) async {
  final token = await ref.read(authProvider.notifier).getValidAccessToken();
  if (token == null) return [];
  return ref.watch(householdRepositoryProvider).listHouseholds(token);
});
