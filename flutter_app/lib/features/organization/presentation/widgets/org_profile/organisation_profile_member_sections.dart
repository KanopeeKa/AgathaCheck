import 'package:flutter/material.dart';

import 'organisation_profile_section_nav.dart';

/// Member-tier profile sections gated by view_* permissions.
class OrganisationProfileMemberSections extends StatelessWidget {
  const OrganisationProfileMemberSections({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context) {
    return OrganisationProfileSectionNav(orgId: orgId);
  }
}
