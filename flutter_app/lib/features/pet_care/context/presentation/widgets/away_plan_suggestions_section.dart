import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_occurrence.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/reschedule_occurrence_flow.dart';
import '../../domain/entities/absence_care_plan.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../away_plan_planner_copy.dart';
import '../providers/care_context_providers.dart';

class AwayPlanSuggestionsSection extends ConsumerWidget {
  const AwayPlanSuggestionsSection({
    super.key,
    required this.absenceId,
    required this.petId,
    required this.startsOn,
    required this.endsOn,
    required this.plannedCareItems,
  });

  final String absenceId;
  final String petId;
  final String startsOn;
  final String endsOn;
  final List<PlannedCareItem> plannedCareItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(absenceCarePlanProvider(absenceId));
    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (plan) {
        final petPlan = plan.pets.where((p) => p.petId == petId).firstOrNull;
        if (petPlan == null) return const SizedBox.shrink();
        return _AwayPlanSuggestionsBody(
          absenceId: absenceId,
          petId: petId,
          startsOn: startsOn,
          endsOn: endsOn,
          petPlan: petPlan,
          plannedCareItems: plannedCareItems,
        );
      },
    );
  }
}

class _AwayPlanSuggestionsBody extends ConsumerWidget {
  const _AwayPlanSuggestionsBody({
    required this.absenceId,
    required this.petId,
    required this.startsOn,
    required this.endsOn,
    required this.petPlan,
    required this.plannedCareItems,
  });

  final String absenceId;
  final String petId;
  final String startsOn;
  final String endsOn;
  final AbsenceCarePlanPet petPlan;
  final List<PlannedCareItem> plannedCareItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dismissed = ref.watch(dismissedPlannerSuggestionsProvider(absenceId));
    final visibleSuggestions = petPlan.suggestions
        .where((s) => !dismissed.contains(_suggestionKey(s)))
        .toList(growable: false);
    final showCarerSummary = petPlan.carerTasks.count > 0;
    if (visibleSuggestions.isEmpty && !showCarerSummary) {
      return const SizedBox.shrink();
    }

    final namesByEntryId = {
      for (final item in plannedCareItems) item.healthEntryId: item.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'away_plan_planner_heading_$petId',
          header: true,
          label: l.careSuggestionTitle,
          child: Text(
            l.careSuggestionTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColorTokens.warmAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...visibleSuggestions.map(
          (suggestion) => _SuggestionRow(
            key: Key('away_plan_planner_suggestion_${suggestion.healthEntryId}'),
            entryName:
                namesByEntryId[suggestion.healthEntryId] ??
                suggestion.healthEntryId,
            suggestion: suggestion,
            onAccept: () => _acceptSuggestion(context, ref, suggestion),
            onDismiss: () => ref
                .read(dismissedPlannerSuggestionsProvider(absenceId).notifier)
                .dismiss(_suggestionKey(suggestion)),
          ),
        ),
        if (showCarerSummary) ...[
          const SizedBox(height: 4),
          Text(
            l.plannerCarerTasks(petPlan.carerTasks.count),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l.plannerDisclaimer,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static String _suggestionKey(CarePlannerSuggestion suggestion) {
    return '${suggestion.healthEntryId}:${suggestion.occurrenceId}';
  }

  Future<void> _acceptSuggestion(
    BuildContext context,
    WidgetRef ref,
    CarePlannerSuggestion suggestion,
  ) async {
    final entry = await ref
        .read(healthRepositoryProvider)
        .getEntry(suggestion.healthEntryId);
    if (entry == null || !context.mounted) return;

    final newDate = parseCalendarDate(suggestion.toDate);
    if (newDate == null) return;

    final occurrence = HealthOccurrence(
      id: suggestion.occurrenceId,
      entryId: suggestion.healthEntryId,
      scheduledDate: parseCalendarDate(suggestion.fromDate)!,
      status: 'pending',
    );

    try {
      final result = await ref
          .read(healthRepositoryProvider)
          .rescheduleOccurrence(
            entry.id,
            occurrence.id,
            newDate,
            reasonCode: 'away_planner',
          );
      RescheduleOccurrenceFlow.invalidateAfterReschedule(ref, entry.id);
      await ref.read(healthEntriesNotifierProvider.notifier).refresh();
      ref.invalidate(absenceCarePlanProvider(absenceId));
      ref.invalidate(
        carePeriodCoverageProvider((
          petId: petId,
          startsOn: startsOn,
          endsOn: endsOn,
        )),
      );

      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.occurrenceRescheduled),
          action: SnackBarAction(
            label: l.snackbarUndo,
            onPressed: () => _undo(context, ref, entry.id, occurrence.id),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careCompletionFailed)),
      );
      ref.invalidate(absenceCarePlanProvider(absenceId));
    }
  }

  Future<void> _undo(
    BuildContext context,
    WidgetRef ref,
    String entryId,
    String occurrenceId,
  ) async {
    try {
      await ref
          .read(healthRepositoryProvider)
          .undoOccurrence(entryId, occurrenceId);
      RescheduleOccurrenceFlow.invalidateAfterReschedule(ref, entryId);
      await ref.read(healthEntriesNotifierProvider.notifier).refresh();
      ref.invalidate(absenceCarePlanProvider(absenceId));
      ref.invalidate(
        carePeriodCoverageProvider((
          petId: petId,
          startsOn: startsOn,
          endsOn: endsOn,
        )),
      );
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careCompletionFailed)),
      );
    }
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    super.key,
    required this.entryName,
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
  });

  final String entryName;
  final CarePlannerSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entryName, style: theme.textTheme.bodyMedium),
          Text(
            AwayPlanPlannerCopy.moveLine(l, suggestion),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            AwayPlanPlannerCopy.reasonLine(l, suggestion),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                key: Key('planner_accept_${suggestion.healthEntryId}'),
                onPressed: onAccept,
                child: Text(l.plannerAccept),
              ),
              TextButton(
                key: Key('planner_not_now_${suggestion.healthEntryId}'),
                onPressed: onDismiss,
                child: Text(l.plannerNotNow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
