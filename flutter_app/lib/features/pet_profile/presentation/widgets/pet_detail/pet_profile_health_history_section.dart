import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_destination_row.dart';

/// Quiet destination group for health issues and timeline (spec §9 region 7).
class PetProfileHealthHistorySection extends StatelessWidget {
  const PetProfileHealthHistorySection({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        key: const Key('pet_profile_health_history'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.petHealthAndHistoryTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          CareDestinationRow(
            key: const Key('pet_profile_nav_health_issues'),
            label: l.healthIssues,
            semanticLabel: l.healthIssues,
            onTap: () => context.push('/pet/$petId/health-issues'),
          ),
          const Divider(height: 1),
          CareDestinationRow(
            key: const Key('pet_profile_nav_timeline'),
            label: l.petTimelineTitle,
            semanticLabel: l.petTimelineTitle,
            onTap: () => context.push('/pet/$petId/timeline'),
          ),
        ],
      ),
    );
  }
}
