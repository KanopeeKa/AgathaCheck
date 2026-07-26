import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/providers/http_client_provider.dart';
import '../../data/datasources/org_legal_documents_remote.dart';
import '../../domain/entities/org_legal_document.dart';
import 'org_provider_deps.dart';

final orgLegalDocumentsRemoteProvider = Provider<OrgLegalDocumentsRemote>((ref) {
  return OrgLegalDocumentsRemote(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(httpClientProvider),
  );
});

class OrgLegalDocumentsNotifier
    extends FamilyAsyncNotifier<Map<String, List<OrgLegalDocument>>, String> {
  @override
  Future<Map<String, List<OrgLegalDocument>>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return {};
    final remote = ref.read(orgLegalDocumentsRemoteProvider);
    return remote.fetchPublicDocuments(orgId: orgId, token: token);
  }
}

final orgLegalDocumentsProvider = AsyncNotifierProvider.family<
    OrgLegalDocumentsNotifier,
    Map<String, List<OrgLegalDocument>>,
    String>(OrgLegalDocumentsNotifier.new);
