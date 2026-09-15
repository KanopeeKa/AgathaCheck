import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/planned_absence.dart';
class PlannedAbsenceHubCard extends StatelessWidget {
  const PlannedAbsenceHubCard({super.key, required this.absence, required this.petsById, this.subdued = false});
  final PlannedAbsence absence; final Map<String, Pet> petsById; final bool subdued;
  static String formatDateRange(AppLocalizations l, PlannedAbsence absence) {
    final startsOn = parseCalendarDate(absence.startsOn); final endsOn = parseCalendarDate(absence.endsOn);
    if (startsOn == null || endsOn == null) return '—';
    return l.careContextAwayPreviewDateRange(formatCalendarDateDisplay(startsOn), formatCalendarDateDisplay(endsOn));
  }
  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!; final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    final dateRange = formatDateRange(l, absence); final petLines = _petLines(l);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: subdued ? colorScheme.onSurfaceVariant : null);
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);
    return Semantics(button: true, label: '$dateRange. ${petLines.join(', ')}', child: Card(
      margin: EdgeInsets.zero, color: subdued ? colorScheme.surfaceContainerLow : null,
      child: InkWell(key: Key('planned_absence_hub_card_${absence.id}'), borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/pc/away/${absence.id}'),
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Icon(Icons.event_outlined, color: subdued ? colorScheme.onSurfaceVariant : colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dateRange, style: titleStyle), const SizedBox(height: 4),
            ...petLines.map((line) => Padding(padding: const EdgeInsets.only(top: 2), child: Text(line, style: bodyStyle))),
          ])),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ])),
      ),
    ));
  }
  List<String> _petLines(AppLocalizations l) {
    if (absence.petIds.isEmpty) return [l.careContextAwayPetsRequired];
    final lines = <String>[]; var onlyPassedAway = true;
    for (final petId in absence.petIds) {
      final pet = petsById[petId]; if (pet == null) continue;
      if (!pet.passedAway) onlyPassedAway = false;
      lines.add('${pet.name}${pet.passedAway ? ' (${l.placementOutcomePassedAway})' : ''}');
    }
    if (lines.isEmpty) return [l.careContextAwayPetsRequired];
    if (onlyPassedAway) return [l.careContextAwayPetsStepBody, ...lines];
    return lines;
  }
}
