import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/providers/http_client_provider.dart';
import '../../data/datasources/org_discovery_remote.dart';
import '../../domain/entities/discoverable_organization.dart';

final orgDiscoveryRemoteProvider = Provider<OrgDiscoveryRemote>((ref) {
  return OrgDiscoveryRemote(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(httpClientProvider),
  );
});

class OrgDiscoveryListNotifier
    extends AsyncNotifier<List<DiscoverableOrganization>> {
  @override
  Future<List<DiscoverableOrganization>> build() async {
    final remote = ref.read(orgDiscoveryRemoteProvider);
    final page = await remote.fetchDiscoverableOrganizations();
    return page.items;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final orgDiscoveryListProvider =
    AsyncNotifierProvider<
      OrgDiscoveryListNotifier,
      List<DiscoverableOrganization>
    >(OrgDiscoveryListNotifier.new);
