import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../auth/application/auth_providers.dart';

import '../data/datasources/health_remote_datasource.dart';
import '../data/repositories/health_repository_impl.dart';
import '../domain/repositories/health_repository.dart';

/// Single health remote data source (authenticated via [authHttpClientProvider]).
final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return HealthRemoteDataSourceImpl(
    baseUrl: baseUrl,
    client: ref.watch(authHttpClientProvider),
  );
});

/// Legacy alias — prefer [healthRemoteDataSourceProvider] or document port providers.
final healthDataSourceProvider = healthRemoteDataSourceProvider;

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final dataSource = ref.watch(healthRemoteDataSourceProvider);
  return HealthRepositoryImpl(dataSource);
});
