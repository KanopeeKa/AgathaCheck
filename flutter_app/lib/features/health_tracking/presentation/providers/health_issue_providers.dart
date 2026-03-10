import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/health_issue_remote_datasource.dart';
import '../../data/repositories/health_issue_repository_impl.dart';
import '../../domain/entities/health_issue.dart';
import '../../domain/repositories/health_issue_repository.dart';
import 'health_providers.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';

final healthIssueDataSourceProvider =
    Provider<HealthIssueRemoteDataSource>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return HealthIssueRemoteDataSourceImpl(baseUrl: baseUrl);
});

final healthIssueRepositoryProvider = Provider<HealthIssueRepository>((ref) {
  final dataSource = ref.watch(healthIssueDataSourceProvider);
  return HealthIssueRepositoryImpl(dataSource);
});

final petHealthIssuesProvider =
    FutureProvider.family<List<HealthIssue>, String>((ref, petId) {
  return ref.read(healthIssueRepositoryProvider).getIssues(petId);
});

class HealthIssueNotifier extends AutoDisposeFamilyAsyncNotifier<List<HealthIssue>, String> {
  @override
  Future<List<HealthIssue>> build(String arg) async {
    return ref.read(healthIssueRepositoryProvider).getIssues(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg));
  }

  Future<void> create(HealthIssue issue) async {
    await ref.read(healthIssueRepositoryProvider).createIssue(issue);
    await refresh();
  }

  Future<void> updateIssue(HealthIssue issue) async {
    await ref.read(healthIssueRepositoryProvider).updateIssue(issue);
    await refresh();
  }

  Future<void> deleteIssue(String id) async {
    await ref.read(healthIssueRepositoryProvider).deleteIssue(id);
    await refresh();
  }

  Future<void> linkEvent(String issueId, String entryId) async {
    await ref.read(healthIssueRepositoryProvider).linkEvent(issueId, entryId);
    await refresh();
  }

  Future<void> unlinkEvent(String issueId, String entryId) async {
    await ref.read(healthIssueRepositoryProvider).unlinkEvent(issueId, entryId);
    await refresh();
  }
}

final healthIssueNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<HealthIssueNotifier, List<HealthIssue>, String>(
        HealthIssueNotifier.new);
