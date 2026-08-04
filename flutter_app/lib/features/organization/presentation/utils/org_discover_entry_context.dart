/// Entry context for the Discover screen (D-v3-DISC-2).
enum OrgDiscoverEntryContext { dashboard, org }

OrgDiscoverEntryContext parseOrgDiscoverEntryContext(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'org':
      return OrgDiscoverEntryContext.org;
    case 'dashboard':
    default:
      return OrgDiscoverEntryContext.dashboard;
  }
}

String orgDiscoverReturnPath({
  required OrgDiscoverEntryContext from,
  String? orgId,
}) {
  switch (from) {
    case OrgDiscoverEntryContext.org:
      final id = orgId?.trim() ?? '';
      if (id.isNotEmpty) return '/o/orgs/$id';
      return '/o/orgs';
    case OrgDiscoverEntryContext.dashboard:
      return '/o/orgs';
  }
}
