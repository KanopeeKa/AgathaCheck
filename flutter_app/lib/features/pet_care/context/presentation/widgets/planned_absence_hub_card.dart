import 'package:flutter/material.dart';
import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../core/widgets/async_state/async_state.dart';
import '../../../presentation/widgets/away_context_icon_chip.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/pet_profile.dart';
import '../../domain/entities/planned_absence.dart';
import '../planned_absence_display.dart';

/// Whether supplemental pet names from [petListProvider] are ready for hub cards.
enum HubPetNamesState { loading, ready, unavailable }

class PlannedAbsenceHubCard extends StatelessWidget {
  const PlannedAbsenceHubCard({
    super.key,
    required this.absence,
    required this.petsById,
    required this.petNamesState,
    this.onRetryPetNames,
    this.subdued = false,
  });
  final PlannedAbsence absence;
  final Map<String, Pet> petsById;
  final HubPetNamesState petNamesState;
  final VoidCallback? onRetryPetNames;
  final bool subdued;

  static String formatDateRange(AppLocalizations l, PlannedAbsence absence) {
    final startsOn = parseCalendarDate(absence.startsOn);
    final endsOn = parseCalendarDate(absence.endsOn);
    if (startsOn == null || endsOn == null) return '—';
    return l.careContextAwayPreviewDateRange(
      formatCalendarDateDisplay(startsOn),
      formatCalendarDateDisplay(endsOn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = PlannedAbsenceDisplay.primaryLabel(l, absence);
    final secondaryDates = PlannedAbsenceDisplay.secondaryDateLine(l, absence);
    final travellerLine = absence.isOwnAbsence == false
        ? PlannedAbsenceDisplay.travellerLine(l, absence)
        : null;
    final petSection = _petSection(context, l);
    final petLines = _resolvedPetLines(l);
    final semanticsPets = _semanticsPetSummary(l, petLines);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: subdued ? colorScheme.onSurfaceVariant : null,
    );
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    return Semantics(
      button: true,
      label: '$primary. $semanticsPets',
      child: Card(
        margin: EdgeInsets.zero,
        color: subdued ? colorScheme.surfaceContainerLow : null,
        child: InkWell(
          key: Key('planned_absence_hub_card_${absence.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => openAwayPlanDetail(context, absence.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AwayContextIconChip(
                  icon: Icons.event_busy_outlined,
                  iconSize: 22,
                  padding: const EdgeInsets.all(8),
                  subdued: subdued,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(primary, style: titleStyle),
                      if (travellerLine != null) ...[
                        const SizedBox(height: 4),
                        Text(travellerLine, style: bodyStyle),
                      ],
                      if (secondaryDates != null) ...[
                        const SizedBox(height: 4),
                        Text(secondaryDates, style: bodyStyle),
                      ],
                      const SizedBox(height: 4),
                      petSection,
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _petSection(BuildContext context, AppLocalizations l) {
    if (absence.petIds.isEmpty) {
      return Text(
        l.careContextAwayPetsRequired,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (petNamesState == HubPetNamesState.loading) {
      return SupplementalStateCaption(
        state: SupplementalState.loading,
        label: l.awayPetsLoading,
      );
    }
    if (petNamesState == HubPetNamesState.unavailable) {
      return SupplementalStateCaption(
        state: SupplementalState.unavailable,
        label: l.awayPetNamesUnavailable,
        onRetry: onRetryPetNames,
        retryKey: const Key('planned_absence_hub_pet_names_retry'),
      );
    }
    final lines = _resolvedPetLines(l);
    if (lines.isEmpty) {
      return SupplementalStateCaption(
        state: SupplementalState.unavailable,
        label: l.awayPetNamesUnavailable,
        onRetry: onRetryPetNames,
        retryKey: const Key('planned_absence_hub_pet_names_retry'),
      );
    }
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(line, style: bodyStyle),
            ),
          )
          .toList(growable: false),
    );
  }

  String _semanticsPetSummary(AppLocalizations l, List<String> petLines) {
    if (absence.petIds.isEmpty) return l.careContextAwayPetsRequired;
    if (petNamesState == HubPetNamesState.loading) return l.awayPetsLoading;
    if (petNamesState == HubPetNamesState.unavailable || petLines.isEmpty) {
      return l.awayPetNamesUnavailable;
    }
    return petLines.join(', ');
  }

  List<String> _resolvedPetLines(AppLocalizations l) {
    if (absence.petIds.isEmpty || petNamesState != HubPetNamesState.ready) {
      return const [];
    }
    final lines = <String>[];
    var onlyPassedAway = true;
    for (final petId in absence.petIds) {
      final pet = petsById[petId];
      if (pet == null) continue;
      if (!pet.passedAway) onlyPassedAway = false;
      lines.add(
        '${pet.name}${pet.passedAway ? ' (${l.placementOutcomePassedAway})' : ''}',
      );
    }
    if (lines.isEmpty) return const [];
    if (onlyPassedAway) return [l.careContextAwayPetsStepBody, ...lines];
    return lines;
  }
}
