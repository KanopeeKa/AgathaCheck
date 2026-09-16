import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/domain/entities/app_experience.dart';
import '../../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/planned_absence.dart';
import '../planned_absence_hub_partition.dart';
import '../providers/care_context_providers.dart';
import '../widgets/planned_absence_hub_card.dart';

class PlannedAbsenceHubScreen extends ConsumerWidget {
  const PlannedAbsenceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final absencesAsync = ref.watch(plannedAbsencesListProvider);
    final petsAsync = ref.watch(petListProvider);
    final petsById = {
      for (final pet in petsAsync.valueOrNull ?? const <Pet>[]) pet.id: pet,
    };

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.careContextAwayFlowTitle,
      backPath: '/pc/home',
      floatingActionButton: absencesAsync.maybeWhen(
        data: (absences) {
          final grouped = PlannedAbsenceHubPartition.partition(absences);
          if (grouped.upcoming.isEmpty && grouped.past.isEmpty) return null;
          return FloatingActionButton.extended(
            key: const Key('planned_absence_hub_add'),
            onPressed: () => context.push('/pc/away/new'),
            icon: const Icon(Icons.add),
            label: Text(l.careContextAwayEntryTitle),
          );
        },
        orElse: () => null,
      ),
      child: absencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _HubError(
          message: l.careContextAwayPreviewError,
          onRetry: () => ref.invalidate(plannedAbsencesListProvider),
        ),
        data: (absences) {
          final grouped = PlannedAbsenceHubPartition.partition(absences);
          if (grouped.upcoming.isEmpty && grouped.past.isEmpty) {
            return _HubEmptyState(
              onPlanAbsence: () => context.push('/pc/away/new'),
            );
          }
          return _HubList(
            upcoming: grouped.upcoming,
            past: grouped.past,
            petsById: petsById,
          );
        },
      ),
    );
  }
}

class _HubList extends StatelessWidget {
  const _HubList({
    required this.upcoming,
    required this.past,
    required this.petsById,
  });
  final List<PlannedAbsence> upcoming;
  final List<PlannedAbsence> past;
  final Map<String, Pet> petsById;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      key: const Key('planned_absence_hub_list'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        if (upcoming.isNotEmpty) ...[
          Text(
            l.upcomingEvents,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._cards(upcoming, false),
        ],
        if (past.isNotEmpty) ...[
          if (upcoming.isNotEmpty) const SizedBox(height: 24),
          Text(
            l.pastIterations,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._cards(past, true),
        ],
      ],
    );
  }

  List<Widget> _cards(List<PlannedAbsence> absences, bool subdued) => [
    for (var i = 0; i < absences.length; i++) ...[
      if (i > 0) const SizedBox(height: 8),
      PlannedAbsenceHubCard(
        absence: absences[i],
        petsById: petsById,
        subdued: subdued,
      ),
    ],
  ];
}

class _HubEmptyState extends StatelessWidget {
  const _HubEmptyState({required this.onPlanAbsence});
  final VoidCallback onPlanAbsence;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l.careContextAwayEntryTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.careContextAwayEntryBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('planned_absence_hub_empty_action'),
              onPressed: onPlanAbsence,
              icon: const Icon(Icons.add),
              label: Text(l.careContextAwayContinue),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubError extends StatelessWidget {
  const _HubError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('planned_absence_hub_retry'),
              onPressed: onRetry,
              child: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}
