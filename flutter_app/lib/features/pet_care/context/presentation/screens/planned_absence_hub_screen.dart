import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/async_state/async_state.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/away_context_icon_chip.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../../domain/entities/planned_absence.dart';
import '../planned_absence_hub_partition.dart';
import '../providers/care_context_providers.dart';
import '../widgets/planned_absence_hub_card.dart';

class PlannedAbsenceHubScreen extends ConsumerWidget {
  const PlannedAbsenceHubScreen({super.key});

  static HubPetNamesState _petNamesState(AsyncValue<List<Pet>> petsAsync) {
    return petsAsync.when(
      loading: () => HubPetNamesState.loading,
      error: (_, __) => HubPetNamesState.unavailable,
      data: (_) => HubPetNamesState.ready,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final absencesAsync = ref.watch(plannedAbsencesListProvider);
    final petsAsync = ref.watch(petListProvider);
    final petsById = {
      for (final pet in petsAsync.valueOrNull ?? const <Pet>[]) pet.id: pet,
    };
    final petNamesState = _petNamesState(petsAsync);
    void retryPetNames() => ref.invalidate(petListProvider);

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.careContextAwayFlowTitle,
      backPath: '/pc/home',
      floatingActionButton: absencesAsync.maybeWhen(
        data: (absences) {
          final grouped = PlannedAbsenceHubPartition.partitionByOwnership(
            absences,
          );
          if (grouped.isEmpty) return null;
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
        loading: () => LabelledProgress(label: l.awayPlansLoading),
        error: (_, __) => AsyncErrorState(
          title: l.careContextAwayPreviewError,
          onRetry: () => ref.invalidate(plannedAbsencesListProvider),
          retryKey: const Key('planned_absence_hub_retry'),
        ),
        data: (absences) {
          final grouped = PlannedAbsenceHubPartition.partitionByOwnership(
            absences,
          );
          if (grouped.isEmpty) {
            return _HubEmptyState(
              onPlanAbsence: () => context.push('/pc/away/new'),
            );
          }
          return _HubList(
            yourAbsences: grouped.yourAbsences,
            otherPeoplesAbsences: grouped.otherPeoplesAbsences,
            petsById: petsById,
            petNamesState: petNamesState,
            onRetryPetNames: retryPetNames,
          );
        },
      ),
    );
  }
}

class _HubList extends StatelessWidget {
  const _HubList({
    required this.yourAbsences,
    required this.otherPeoplesAbsences,
    required this.petsById,
    required this.petNamesState,
    required this.onRetryPetNames,
  });

  final List<PlannedAbsence> yourAbsences;
  final List<PlannedAbsence> otherPeoplesAbsences;
  final Map<String, Pet> petsById;
  final HubPetNamesState petNamesState;
  final VoidCallback onRetryPetNames;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      key: const Key('planned_absence_hub_list'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        if (yourAbsences.isNotEmpty) ...[
          Semantics(
            identifier: 'planned_absence_hub_your_absences_heading',
            label: l.careContextHubYourAbsences,
            header: true,
            container: true,
            child: ExcludeSemantics(
              child: Text(
                l.careContextHubYourAbsences,
                key: const Key('planned_absence_hub_your_absences_heading'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._cards(yourAbsences, false),
        ],
        if (otherPeoplesAbsences.isNotEmpty) ...[
          if (yourAbsences.isNotEmpty) const SizedBox(height: 24),
          Semantics(
            identifier: 'planned_absence_hub_other_absences_heading',
            label: l.careContextHubOtherPeoplesAbsences,
            header: true,
            container: true,
            child: ExcludeSemantics(
              child: Text(
                l.careContextHubOtherPeoplesAbsences,
                key: const Key('planned_absence_hub_other_absences_heading'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._cards(otherPeoplesAbsences, false),
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
        petNamesState: petNamesState,
        onRetryPetNames: onRetryPetNames,
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
            const AwayContextIconChip(
              iconSize: 32,
              padding: EdgeInsets.all(14),
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
