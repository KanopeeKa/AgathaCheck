import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/core/widgets/async_state/async_state.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/core/widgets/pet_care_illustrated_empty_state.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';

/// Dedicated health issues screen with expandable issue cards.
class PetHealthIssuesScreen extends ConsumerWidget {
  const PetHealthIssuesScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final experience = AppExperience.petCare;
    final issuesAsync = ref.watch(healthIssueNotifierProvider(petId));
    final controller = HealthIssuesController(ref);

    void onAddIssue() => controller.showAddIssueDialog(context, petId);

    final canAdd = issuesAsync.maybeWhen(
      data: (_) => true,
      orElse: () => false,
    );

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.healthIssues,
      backPath: petDetailBackPath(context, petId),
      contextualActions: [
        IconButton(
          key: const Key('health_issues_add_app_bar'),
          tooltip: l.addHealthIssue,
          icon: const Icon(Icons.add),
          onPressed: canAdd ? onAddIssue : null,
        ),
      ],
      child: issuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AsyncErrorState(
          title: l.loadErrorHealthIssues,
          onRetry: () => ref.invalidate(healthIssueNotifierProvider(petId)),
          retryKey: const Key('health_issues_load_retry'),
        ),
        data: (issues) {
          if (issues.isEmpty) {
            return ColoredBox(
              color: CareSurfaceTokens.collectionBackground(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: PetCareIllustratedEmptyState(
                  key: const Key('health_issues_empty'),
                  title: l.healthIssuesEmptyTitle,
                  body: l.healthIssuesEmptyBody,
                  actionLabel: l.addHealthIssue,
                  actionIcon: Icons.add,
                  actionKey: const Key('health_issues_empty_add'),
                  onAction: onAddIssue,
                ),
              ),
            );
          }

          return ColoredBox(
            color: CareSurfaceTokens.collectionBackground(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: CareCollectionInsetList(
                semanticLabel: l.healthIssues,
                children: [
                  for (var i = 0; i < issues.length; i++)
                    CareCollectionInsetItem(
                      showDividerBefore: i > 0,
                      child: HealthIssueCard(
                        key: Key('health_issue_list_${issues[i].id}'),
                        petId: petId,
                        issue: issues[i],
                        controller: controller,
                        inCollection: true,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
