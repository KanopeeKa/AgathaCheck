import 'package:flutter/material.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import 'org_discovery_list.dart';

class OrgDiscoverySection extends StatelessWidget {
  const OrgDiscoverySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return DashboardSection(
      title: l.discoverOrganizations,
      previewBuilder: (_) => const OrgDiscoveryList(),
    );
  }
}
