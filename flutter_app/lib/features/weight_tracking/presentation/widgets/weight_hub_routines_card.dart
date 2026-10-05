import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/weight_overview.dart';
import '../utils/weight_hub_labels.dart';

class WeightHubRoutinesCard extends StatelessWidget {
  const WeightHubRoutinesCard({
    required this.petId,
    required this.overview,
    super.key,
  });

  final String petId;
  final WeightOverview? overview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final routines = overview?.routines ?? [];

    return Card(
      key: const Key('weight_hub_routines'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: routines.isEmpty
            ? _NoRoutineBody(
                l: l,
                theme: theme,
                onSetUp: () => context.push('/pet/$petId/care/add'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.weightRoutinesTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final routine in routines)
                    _RoutineRow(petId: petId, routine: routine, l: l),
                ],
              ),
      ),
    );
  }
}

class _NoRoutineBody extends StatelessWidget {
  const _NoRoutineBody({
    required this.l,
    required this.theme,
    required this.onSetUp,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.weightNoRoutineTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.weightNoRoutineBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: onSetUp,
          child: Text(l.weightSetUpRoutine),
        ),
      ],
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.petId,
    required this.routine,
    required this.l,
  });

  final String petId;
  final WeightRoutine routine;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (routine.status == 'paused') {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(routine.name),
        subtitle: Text(l.weightRoutinePaused),
      );
    }
    final next = routine.next;
    if (next == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(routine.name),
      );
    }
    final dateLabel = DateFormat.yMMMd().format(
      calendarDateOnly(next.scheduledDate),
    );
    final statusWord = careOccurrenceStatusLabel(l, next.status);
    final subtitle = l.weightNextWeighIn(dateLabel, statusWord);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(routine.name),
      subtitle: Text(subtitle),
      onTap: () => context.push('/pet/$petId/events/${routine.entryId}'),
    );
  }
}
