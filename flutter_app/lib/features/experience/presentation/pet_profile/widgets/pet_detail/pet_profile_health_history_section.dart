import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/widgets/pet_care_dashboard_section_header.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

import 'pet_profile_weight_insight_section.dart';

/// Quiet destination group for health issues and timeline (spec §9 region 7).
class PetProfileHealthHistorySection extends ConsumerWidget {
  const PetProfileHealthHistorySection({
    super.key,
    required this.petId,
    required this.pet,
  });

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final issuesAsync = ref.watch(healthIssueNotifierProvider(petId));
    final healthIssuesTrailing = issuesAsync.when(
      data: (issues) => issues.isEmpty ? null : '${issues.length}',
      loading: () => null,
      error: (_, __) => null,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, kPetDetailSectionInsetTop, 16, 0),
      child: Column(
        key: const Key('pet_profile_health_history'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetCareDashboardSectionChrome(
            title: l.petHealthAndHistoryTitle,
            titleMaxLines: 2,
          ),
          const SizedBox(height: kPetDetailSectionTitleGap),
          PetProfileWeightInsightSection(
            petId: petId,
            pet: pet,
            insetPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: kPetDetailSectionTitleGap),
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
