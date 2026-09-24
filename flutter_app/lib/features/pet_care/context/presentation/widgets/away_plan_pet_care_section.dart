import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/widgets/care_event_row_pet_avatar.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../pet_profile/presentation/widgets/care_family_icon.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../../../../health_tracking/presentation/widgets/care_event_status_line.dart';
import '../../../../health_tracking/presentation/widgets/reschedule_occurrence_flow.dart';
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
      carePeriodCoverageProvider((
        petId: petId,
        startsOn: startsOn,
        endsOn: endsOn,
      )),
    );

    return Card(
      key: Key('away_plan_pet_care_$petId'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: coverageAsync.when(
          loading: () => _PetCareHeader(
            petId: petId,
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
            petId: petId,
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
          data: (result) => _PetCareBody(
            petId: petId,
            petName: petName,
            result: result,
            startsOn: startsOn,
            endsOn: endsOn,
          ),
        ),
      ),
    );
  }
}

class _PetCareHeader extends StatelessWidget {
  const _PetCareHeader({
    required this.petId,
    required this.petName,
    required this.child,
  });

  final String petId;
  final String petName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PetHeaderTapTarget(petId: petId, petName: petName),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PetHeaderTapTarget extends ConsumerWidget {
  const _PetHeaderTapTarget({required this.petId, required this.petName});

  final String petId;
  final String petName;

  static const _kMinTouchTarget = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final pet = ref.watch(petByIdProvider(petId)).valueOrNull;

    return Semantics(
      identifier: 'away_plan_pet_header_$petId',
      button: true,
      label: l.petDetailsFor(petName),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openPetDetail(context, petId),
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _kMinTouchTarget),
            child: Row(
              children: [
                CareEventRowPetAvatar(pet: pet, petName: petName),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    petName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetCareBody extends StatelessWidget {
  const _PetCareBody({
    required this.petId,
    required this.petName,
    required this.result,
    required this.startsOn,
    required this.endsOn,
  });

  final String petId;
  final String petName;
  final CarePeriodCoverageResult result;
  final String startsOn;
  final String endsOn;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PetHeaderTapTarget(petId: petId, petName: petName),
        const SizedBox(height: 8),
        Text(
          CarePeriodCoverageCopy.summary(l, result),
          style: theme.textTheme.bodyLarge,
        ),
        if (CarePeriodCoverageCopy.indeterminateQualifier(l, result) !=
            null) ...[
          const SizedBox(height: 8),
          Text(
            CarePeriodCoverageCopy.indeterminateQualifier(l, result)!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (result.plannedCareItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            header: true,
            identifier: 'away_plan_planned_care_heading',
            label: l.awayPlanningScheduleDatedTitle,
            child: Text(
              l.awayPlanningScheduleDatedTitle,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          ...result.plannedCareItems.map(
            (item) => _PlannedCareRow(
              petId: petId,
              item: item,
              startsOn: startsOn,
              endsOn: endsOn,
            ),
          ),
          if (result.showsEstimateFootnote) ...[
            const SizedBox(height: 8),
            Text(
              l.awayPlanningEstimateFootnote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (result.showsChainAnchorExplainer) ...[
            const SizedBox(height: 8),
            Text(
              l.awayPlanningChainAnchorExplainer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _PlannedCareRow extends ConsumerWidget {
  const _PlannedCareRow({
    required this.petId,
    required this.item,
    required this.startsOn,
    required this.endsOn,
  });

  final String petId;
  final PlannedCareItem item;
  final String startsOn;
  final String endsOn;

  static const _kMinTouchTarget = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scheduleLine = AwayPlanScheduleCopy.plannedCareScheduleLine(l, item);
    final detailLines = AwayPlanScheduleCopy.plannedCareDetailLines(l, item);
    final openStatusLine = AwayPlanScheduleCopy.openOccurrenceStatusLine(
      l,
      item,
      colorScheme,
    );
    final inWindowLine = AwayPlanScheduleCopy.inWindowLine(l, item);
    final viewLabel = '${item.name}. $scheduleLine';
    final canPlanThis =
        !item.isPaused &&
        (item.openOccurrence?.occurrenceId ?? item.occurrenceId) != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        identifier: 'away_plan_planned_care_${item.healthEntryId}',
        button: true,
        label: viewLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => openPetEventView(
              context,
              petId: petId,
              entryId: item.healthEntryId,
            ),
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _kMinTouchTarget),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CareFamilyIcon.forWire(
                    type: item.type,
                    careFamily: item.careFamily,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AwayPlanScheduleCopy.plannedCareRowTitle(item),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          scheduleLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!item.isPaused && openStatusLine != null)
                          CareEventStatusLineView(
                            status: openStatusLine,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        if (!item.isPaused && inWindowLine != null)
                          Text(
                            inWindowLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ...detailLines.map(
                          (line) => Text(
                            line,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (canPlanThis) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              key: Key(
                                'away_plan_plan_this_${item.healthEntryId}',
                              ),
                              onPressed: () =>
                                  RescheduleOccurrenceFlow.fromAwayPlanRow(
                                    context: context,
                                    ref: ref,
                                    item: item,
                                    startsOn: startsOn,
                                    endsOn: endsOn,
                                  ),
                              child: Text(l.awayPlanningPlanThis),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
