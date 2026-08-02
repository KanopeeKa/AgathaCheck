import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/organization.dart';
import 'org_provider_deps.dart';
import 'org_provider_list.dart';

class OrganisationProfileView {
  const OrganisationProfileView({
    required this.organization,
    required this.isMember,
  });

  final Organization organization;
  final bool isMember;
}

class OrganisationProfileNotifier
    extends FamilyAsyncNotifier<OrganisationProfileView, String> {
  @override
  Future<OrganisationProfileView> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    final repo = ref.read(organizationRepositoryProvider);
    final organization = await repo.getPublicOrganization(orgId, token: token);

    final memberOrgs = ref.watch(organizationListProvider);
    final isMember = memberOrgs.when(
      data: (orgs) => orgs.any((org) => org.id == orgId),
      loading: () => false,
      error: (_, __) => false,
    );

    return OrganisationProfileView(organization: organization, isMember: isMember);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final organisationProfileProvider =
    AsyncNotifierProvider.family<
      OrganisationProfileNotifier,
      OrganisationProfileView,
      String
    >(OrganisationProfileNotifier.new);
