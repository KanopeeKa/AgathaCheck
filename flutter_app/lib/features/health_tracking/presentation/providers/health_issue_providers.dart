import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/health_issue_remote_datasource.dart';
import '../../data/repositories/health_issue_repository_impl.dart';
import '../../domain/entities/health_issue.dart';
import '../../domain/entities/health_issue_document.dart';
import '../../domain/repositories/health_issue_repository.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';

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

final petHealthIssuesProvider =
    FutureProvider.family<List<HealthIssue>, String>((ref, petId) {
      final token = ref.watch(authProvider).accessToken;
      if (token == null) return Future.value([]);
      return ref.read(healthIssueRepositoryProvider).getIssues(petId, token);
    });

final healthIssueDocumentsProvider = FutureProvider.autoDispose
    .family<List<HealthIssueDocument>, String>((ref, issueId) async {
      final token = ref.watch(authProvider).accessToken;
      if (token == null) return [];
      return ref
          .read(healthIssueRepositoryProvider)
          .getDocuments(issueId, token);
    });

class HealthIssueNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<HealthIssue>, String> {
  String? get _token => ref.read(authProvider).accessToken;

  @override
  Future<List<HealthIssue>> build(String arg) async {
    final token = _token;
    if (token == null) return [];
    return ref.read(healthIssueRepositoryProvider).getIssues(arg, token);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg));
  }

  Future<void> create(HealthIssue issue) async {
    final token = _token;
    if (token == null) return;
    await ref.read(healthIssueRepositoryProvider).createIssue(issue, token);
    await refresh();
  }

  Future<void> updateIssue(HealthIssue issue) async {
    final token = _token;
    if (token == null) return;
    await ref.read(healthIssueRepositoryProvider).updateIssue(issue, token);
    await refresh();
  }

  Future<void> deleteIssue(String id) async {
    final token = _token;
    if (token == null) return;
    await ref.read(healthIssueRepositoryProvider).deleteIssue(id, token);
    await refresh();
  }

  Future<void> linkEvent(String issueId, String entryId) async {
    final token = _token;
    if (token == null) return;
    await ref
        .read(healthIssueRepositoryProvider)
        .linkEvent(issueId, entryId, token);
    await refresh();
  }

  Future<void> unlinkEvent(String issueId, String entryId) async {
    final token = _token;
    if (token == null) return;
    await ref
        .read(healthIssueRepositoryProvider)
        .unlinkEvent(issueId, entryId, token);
    await refresh();
  }

  Future<HealthIssueDocument> uploadDocument(
    String issueId,
    List<int> bytes,
    String filename,
    String mimeType,
  ) async {
    final token = _token;
    if (token == null) throw Exception('Not authenticated');
    final doc = await ref
        .read(healthIssueRepositoryProvider)
        .uploadDocument(issueId, bytes, filename, mimeType, token);
    ref.invalidate(healthIssueDocumentsProvider(issueId));
    return doc;
  }

  Future<void> deleteDocument(String issueId, String documentId) async {
    final token = _token;
    if (token == null) return;
    await ref
        .read(healthIssueRepositoryProvider)
        .deleteDocument(issueId, documentId, token);
    ref.invalidate(healthIssueDocumentsProvider(issueId));
  }
}

final healthIssueNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<HealthIssueNotifier, List<HealthIssue>, String>(
      HealthIssueNotifier.new,
    );
