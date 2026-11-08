import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

/// Quiet destination group for health issues and timeline (spec §9 region 7).
class PetProfileHealthHistorySection extends ConsumerWidget {
  const PetProfileHealthHistorySection({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final issuesAsync = ref.watch(healthIssueNotifierProvider(petId));
    final healthIssuesTrailing = issuesAsync.when(
      data: (issues) => issues.isEmpty ? null : '${issues.length}',
      loading: () => null,
      error: (_, __) => null,
    );

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
            trailingDetail: healthIssuesTrailing,
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
