import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../auth/auth.dart';

import '../data/datasources/health_issue_remote_datasource.dart';
import '../data/repositories/health_documents_repository_impl.dart';
import '../data/repositories/health_issue_repository_impl.dart';
import '../domain/repositories/health_documents_repository.dart';
import '../domain/repositories/health_issue_repository.dart';

final healthDocumentsRepositoryProvider = Provider<HealthDocumentsRepository>((
  ref,
) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return HealthDocumentsRepositoryImpl(
    baseUrl: baseUrl,
    client: ref.watch(authHttpClientProvider),
  );
});

final healthIssueDataSourceProvider = Provider<HealthIssueRemoteDataSource>((
  ref,
) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return HealthIssueRemoteDataSourceImpl(
    baseUrl: baseUrl,
    client: ref.watch(authHttpClientProvider),
  );
});

final healthIssueRepositoryProvider = Provider<HealthIssueRepository>((ref) {
  final dataSource = ref.watch(healthIssueDataSourceProvider);
  return HealthIssueRepositoryImpl(dataSource);
});
