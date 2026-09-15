import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../away_plan_schedule_copy.dart';
import '../care_period_coverage_copy.dart';
import '../providers/care_context_providers.dart';

class AwayPlanPetCareSection extends ConsumerWidget {
  const AwayPlanPetCareSection({
    super.key,
    required this.petId,
    required this.petName,
    required this.startsOn,
    required this.endsOn,
    required this.onRetry,
  });

  final String petId;
  final String petName;
  final String startsOn;
  final String endsOn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final coverageAsync = ref.watch(
      carePeriodCoverageProvider((petId: petId, startsOn: startsOn, endsOn: endsOn)),
    );

    return Card(
      key: Key('away_plan_pet_care_$petId'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: coverageAsync.when(
          loading: () => _PetCareHeader(
            petName: petName,
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l.careContextAwayPreviewLoading)),
              ],
            ),
          ),
          error: (_, __) => _PetCareHeader(
            petName: petName,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.careContextAwayPreviewError),
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: Text(l.retry)),
              ],
            ),
          ),
          data: (result) => _PetCareBody(petName: petName, result: result),
        ),
      ),
    );
  }
}

class _PetCareHeader extends StatelessWidget {
  const _PetCareHeader({required this.petName, required this.child});

  final String petName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          petName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PetCareBody extends StatelessWidget {
  const _PetCareBody({required this.petName, required this.result});

  final String petName;
  final CarePeriodCoverageResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          petName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          CarePeriodCoverageCopy.summary(l, result),
          style: theme.textTheme.bodyLarge,
        ),
        if (CarePeriodCoverageCopy.indeterminateQualifier(l, result) != null) ...[
          const SizedBox(height: 8),
          Text(
            CarePeriodCoverageCopy.indeterminateQualifier(l, result)!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (result.routineItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l.awayPlanningScheduleRoutineTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...result.routineItems.map(
            (item) => _RoutineRow(item: item),
          ),
        ],
        if (result.datedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l.awayPlanningScheduleDatedTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...result.datedItems.map(
            (item) => _DatedRow(item: item),
          ),
        ],
        if (result.uncertainties.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l.awayPlanningScheduleIndeterminateTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...result.uncertainties.map(
            (uncertainty) => _IndeterminateRow(uncertainty: uncertainty),
          ),
        ],
      ],
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.item});

  final CarePeriodRoutineItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.repeat,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AwayPlanScheduleCopy.routineRowTitle(item),
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  AwayPlanScheduleCopy.routineRowSubtitle(l, item),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatedRow extends StatelessWidget {
  const _DatedRow({required this.item});

  final CarePeriodProjectionItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isPending ? Icons.circle_outlined : Icons.check_circle_outline,
            size: 18,
            color: item.isPending
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.bodyMedium),
                Text(
                  AwayPlanScheduleCopy.datedRowStatus(l, item),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndeterminateRow extends StatelessWidget {
  const _IndeterminateRow({required this.uncertainty});

  final CarePeriodUncertainty uncertainty;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = uncertainty.name.isNotEmpty
        ? '~ ${uncertainty.name}'
        : l.awayPlanningIndeterminateGeneric;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.help_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium),
                Text(
                  AwayPlanScheduleCopy.indeterminateRowSubtitle(l, uncertainty),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
