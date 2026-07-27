import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/presentation/providers/experience_providers.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../health_tracking/presentation/widgets/health_issue_card.dart';
import '../controllers/health_issues_controller.dart';

/// Dedicated health issues screen with expandable issue cards.
class PetHealthIssuesScreen extends ConsumerWidget {
  const PetHealthIssuesScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final experience = ref.watch(resolvedExperienceProvider);
    final issuesAsync = ref.watch(healthIssueNotifierProvider(petId));
    final controller = HealthIssuesController(ref);

    void onAddIssue() => controller.showAddIssueDialog(context, petId);

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.healthIssues,
      contextualActions: [
        IconButton(
          key: const Key('health_issues_add_app_bar'),
          tooltip: l.addHealthIssue,
          icon: const Icon(Icons.add),
          onPressed: onAddIssue,
        ),
      ],
      child: issuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l.errorWithMessage(e.toString()),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (issues) {
          if (issues.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.noEntriesYet,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return HealthIssueCard(
                key: Key('health_issue_list_${issue.id}'),
                petId: petId,
                issue: issue,
                controller: controller,
              );
            },
          );
        },
      ),
    );
  }
}
