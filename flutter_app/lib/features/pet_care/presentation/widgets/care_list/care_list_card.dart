import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../../../../pet_profile/pet_profile.dart';
import '../../../../../core/widgets/care_mark_done_button.dart';
import '../care_agenda/care_agenda_row_tile.dart';
import '../care_surface/care_item_status_pill.dart';

/// Multi-line care card for global All care (CARE-ITEM-R-024).
class CareListTodayCard extends StatelessWidget {
  const CareListTodayCard({
    super.key,
    required this.entry,
    required this.content,
    required this.onOpen,
    required this.onDone,
    this.petName,
  });

  final HealthEntry entry;
  final CareListTodayContent content;
  final VoidCallback onOpen;
  final VoidCallback? onDone;
  final String? petName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final schedule = entry.schedule!;
    final family = entry.careFamily ?? inferCareFamily(entry);
    final subtitle = [
      ?petName,
      careFamilyLabel(l, family),
      formatRecurrenceSummary(l, entry),
    ].join(' · ');

    return Semantics(
      identifier: content.isStack
          ? 'care_list_stack_${entry.id}'
          : 'care_list_card_${entry.id}',
      container: true,
      label: [?petName, entry.name].join(', '),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CareFamilyIcon.forEntry(entry),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (content.showMarkDone && onDone != null)
                    CareMarkDoneTrailing(
                      entryId: entry.id,
                      careName: entry.name,
                      onPressed: onDone!,
                    ),
                ],
              ),
              if (content.isStack) ...[
                const SizedBox(height: 8),
                _StackLine(count: content.stackCount, l: l),
              ],
              for (final line in content.openLines) ...[
                const SizedBox(height: 8),
                _OpenSlotLine(line: line, schedule: schedule, l: l),
              ],
              for (final done in content.quietDone) ...[
                const SizedBox(height: 8),
                _QuietDoneLine(
                  completion: done,
                  l: l,
                  semanticsId: 'care_list_done_${done.occurrenceId}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CareListUpcomingCard extends StatelessWidget {
  const CareListUpcomingCard({
    super.key,
    required this.row,
    required this.onOpen,
    required this.onDone,
    this.petName,
  });

  final CareAgendaRow<HealthEntry> row;
  final VoidCallback onOpen;
  final VoidCallback onDone;
  final String? petName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entry = row.item;
    final status = careAgendaStatusText(
      row,
      l,
      formatDate: formatHealthEntryStatusDate,
    );
    final family = entry.careFamily ?? inferCareFamily(entry);
    final subtitle = [
      ?petName,
      careFamilyLabel(l, family),
      formatRecurrenceSummary(l, entry),
    ].join(' · ');
    final label = [?petName, entry.name, status].join(', ');

    return Semantics(
      identifier: 'care_list_card_${entry.id}',
      label: '$label. ${l.careRowOpensItem}',
      button: true,
      onTap: onOpen,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CareFamilyIcon.forEntry(entry),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      HealthEntryStatusLabel(
                        text: status,
                        treatment: careAgendaStatusTreatment(row, colorScheme),
                        compact: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CareMarkDoneButton(
                  key: Key('pet_care_action_done_${entry.id}'),
                  onPressed: onDone,
                  semanticLabel: l.careMarkDoneLabel(entry.name),
                  semanticsIdentifier: 'pet_care_action_done_${entry.id}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CareMarkDoneTrailing extends StatelessWidget {
  const CareMarkDoneTrailing({
    super.key,
    required this.entryId,
    required this.careName,
    required this.onPressed,
  });

  final String entryId;
  final String careName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CareMarkDoneButton(
      key: Key('pet_care_action_done_$entryId'),
      onPressed: onPressed,
      semanticLabel: l.careMarkDoneLabel(careName),
      semanticsIdentifier: 'pet_care_action_done_$entryId',
    );
  }
}

class _StackLine extends StatelessWidget {
  const _StackLine({required this.count, required this.l});

  final int count;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'care_list_stack_line',
      label: l.careStackCount(count),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CareItemStatusPill(
          label: l.careStackCount(count),
          tone: CareItemStatusTone.overdue,
        ),
      ),
    );
  }
}

class _OpenSlotLine extends StatelessWidget {
  const _OpenSlotLine({
    required this.line,
    required this.schedule,
    required this.l,
  });

  final CareListSlotLine line;
  final CareItemSchedule schedule;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pill = openOccurrencePillStyle(l, line.status);
    final isToday = line.occurrence.date == schedule.asOf.date;
    final parts = <String>[
      if (!isToday) formatHealthEntryStatusDate(line.occurrence.date),
      ?line.occurrence.time,
    ].whereType<String>();
    final when = parts.join(' · ');
    return Semantics(
      identifier: 'care_list_line_${line.occurrence.id}',
      label: '$when, ${pill.label}',
      child: Row(
        children: [
          Expanded(child: Text(when, style: theme.textTheme.bodyMedium)),
          CareItemStatusPill(label: pill.label, tone: _toneForPill(pill.tone)),
        ],
      ),
    );
  }

  CareItemStatusTone _toneForPill(OccurrencePillTone tone) => switch (tone) {
    OccurrencePillTone.overdue => CareItemStatusTone.overdue,
    OccurrencePillTone.due => CareItemStatusTone.due,
    OccurrencePillTone.notRecorded => CareItemStatusTone.notRecorded,
    _ => CareItemStatusTone.neutral,
  };
}

class _QuietDoneLine extends StatelessWidget {
  const _QuietDoneLine({
    required this.completion,
    required this.l,
    required this.semanticsId,
  });

  final CompletionToday completion;
  final AppLocalizations l;
  final String semanticsId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = l.careDoneAt(completion.time ?? '');
    return Semantics(
      identifier: semanticsId,
      label: label,
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
