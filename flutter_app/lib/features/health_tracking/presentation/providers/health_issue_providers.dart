import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/health_documents_providers.dart';
import '../../domain/entities/health_document.dart';
import '../../domain/entities/health_issue.dart';
import '../../domain/entities/health_issue_document.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';

final petHealthIssuesProvider =
    FutureProvider.family<List<HealthIssue>, String>((ref, petId) {
      final token = ref.watch(authProvider).accessToken;
      if (token == null) return Future.value([]);
      return ref.read(healthIssueRepositoryProvider).getIssues(petId, token);
    });

HealthIssueDocument _mapHealthDocumentToIssue(HealthDocument doc) {
  return HealthIssueDocument(
    id: doc.id,
    healthIssueId: doc.healthIssueId ?? '',
    url: doc.url,
  );
}

final healthIssueDocumentsProvider = FutureProvider.autoDispose
    .family<List<HealthIssueDocument>, String>((ref, issueId) async {
      final token = ref.watch(authProvider).accessToken;
      if (token == null) return [];
      final docs = await ref
          .read(healthDocumentsRepositoryProvider)
          .listIssueDocuments(issueId);
      return docs.map(_mapHealthDocumentToIssue).toList();
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
    if (_token == null) throw Exception('Not authenticated');
    final doc = await ref
        .read(healthDocumentsRepositoryProvider)
        .uploadIssueDocument(
          issueId,
          Uint8List.fromList(bytes),
          filename,
          mimeType,
        );
    ref.invalidate(healthIssueDocumentsProvider(issueId));
    return _mapHealthDocumentToIssue(doc);
  }

  Future<void> deleteDocument(String issueId, String documentId) async {
    if (_token == null) return;
    await ref
        .read(healthDocumentsRepositoryProvider)
        .removeIssueDocument(issueId, documentId);
    ref.invalidate(healthIssueDocumentsProvider(issueId));
  }
}

final healthIssueNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<HealthIssueNotifier, List<HealthIssue>, String>(
      HealthIssueNotifier.new,
    );
