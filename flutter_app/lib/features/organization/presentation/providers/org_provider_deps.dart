import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/organization_remote_datasource.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../domain/repositories/organization_repository.dart';

final orgRemoteDataSourceProvider = Provider<OrganizationRemoteDataSource>((
  ref,
) {
  return OrganizationRemoteDataSource(
    // Route through the shared base URL ('/backend' on web) instead of the
    // datasource's own default, so all features hit one consistent prefix.
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(authHttpClientProvider),
  );
});

/// The seam the presentation layer depends on. Notifiers/screens go through this
/// repository rather than touching the remote datasource directly (clean
/// architecture); override it in tests with a fake repository.
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepositoryImpl(ref.watch(orgRemoteDataSourceProvider));
});

final orgTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).accessToken;
});
