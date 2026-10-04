import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/analytics_providers.dart';
import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../care_item.dart';
import '../../../pet_care/presentation/widgets/care_surface/care_item_module.dart';
import '../../../pet_care/presentation/widgets/care_surface/care_item_section_header.dart';
import '../../../pet_care/presentation/widgets/care_surface/care_item_status_pill.dart';
import '../../../../core/widgets/care_mark_done_button.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/domain/entities/health_occurrence.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../health_tracking/presentation/widgets/pet_event_occurrence_actions.dart';
import '../../../health_tracking/presentation/widgets/pet_event_view_providers.dart';
import '../sheets/plan_another_date_sheet.dart';
import 'care_occurrence_menu.dart';

/// Needs attention on the Care Item view (§18.6.5): every open occurrence
/// as a line (date, status, tick); a line opens its occurrence screen. A
/// stack adds Mark all as done / Skip all (one command, one Undo). The
/// estimated next date is a subtitle only (AID-10).
class CareItemNeedsAttentionSection extends ConsumerStatefulWidget {
  const CareItemNeedsAttentionSection({
    super.key,
    required this.entry,
    required this.schedule,
    required this.muted,
  });

  final HealthEntry entry;
  final CareItemSchedule schedule;
  final bool muted;

  @override
  ConsumerState<CareItemNeedsAttentionSection> createState() =>
      _CareItemNeedsAttentionSectionState();
}

class _CareItemNeedsAttentionSectionState
    extends ConsumerState<CareItemNeedsAttentionSection> {
  bool _busy = false;

  CareItemSchedule get _s => widget.schedule;

  Future<void> _refresh() async {
    await ref.read(healthEntriesNotifierProvider.notifier).refresh();
    ref.invalidate(petHealthEntryByIdProvider);
  }

  Future<void> _bulk({required bool done}) async {
    if (_busy) return;
    final l = AppLocalizations.of(context)!;
    final ids = startedOccurrences(_s).map((o) => o.id).toList();
    setState(() => _busy = true);
    final service = ref.read(careCompletionServiceProvider);
    final outcome = await service.resolveStack(
      entryId: _s.entryId,
      given: done ? ids : const [],
      notGiven: done ? const [] : ids,
    );
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (outcome) {
      case CareSucceeded(:final value):
        ref.read(analyticsServiceProvider).capture('care_stack_resolved', {
          'count': ids.length,
          'done': done,
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.careDoneSnackbar(_s.name)),
            action: value.undoToken == null
                ? null
                : SnackBarAction(
                    label: l.snackbarUndo,
                    onPressed: () async {
                      await service.undo(
                        entryId: _s.entryId,
                        undoToken: value.undoToken,
                      );
                      await _refresh();
                    },
                  ),
          ),
        );
      case CareFailed(failure: CareNotOpenFailure()):
        messenger.showSnackBar(SnackBar(content: Text(l.careAlreadyUpdated)));
      case CareFailed():
        messenger.showSnackBar(SnackBar(content: Text(l.careCommandFailed)));
    }
  }

  Future<void> _occurrenceMenuAction(
    BuildContext context,
    WidgetRef ref,
    OpenOccurrence occurrence,
    CareOccurrenceMenuAction action,
  ) async {
    final l = AppLocalizations.of(context)!;
    final service = ref.read(careCompletionServiceProvider);
    switch (action) {
      case CareOccurrenceMenuAction.skip:
        final outcome = await service.skip(
          entryId: _s.entryId,
          occurrenceId: occurrence.id,
        );
        await _refresh();
        if (!context.mounted) return;
        if (outcome is CareFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.careCommandFailed)),
          );
        }
      case CareOccurrenceMenuAction.postpone:
        await ref
            .read(healthEntriesNotifierProvider.notifier)
            .pauseCareItem(_s.entryId);
        PetEventOccurrenceActions.invalidateOccurrenceData(ref, _s.entryId);
        await _refresh();
      case CareOccurrenceMenuAction.planAnother:
        final added = await showPlanAnotherDateSheet(
          context,
          ref,
          entryId: _s.entryId,
          initialDate: occurrence.date,
        );
        if (added == true) await _refresh();
      case CareOccurrenceMenuAction.addNote:
        openOccurrenceScreen(
          context,
          petId: widget.entry.petId,
          entryId: widget.entry.id,
          occurrenceId: occurrence.id,
          source: 'care_item',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stack = isStack(_s);
    final leading = leadingOccurrence(_s);
    final estimated = _s.estimatedNext;
    return Semantics(
      identifier: 'care_item_needs_attention_section',
      child: CareItemModule(
        key: const Key('care_item_needs_attention_section'),
        semanticLabel: l.careItemNeedsAttentionTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CareItemSectionHeader(
              title: l.careItemNeedsAttentionTitle,
              icon: Icons.flag_outlined,
            ),
            const SizedBox(height: 8),
            for (final occ in _s.openOccurrences)
              _OccurrenceLine(
                entry: widget.entry,
                schedule: _s,
                occurrence: occ,
                muted: widget.muted || _busy,
                onChanged: _refresh,
              ),
            if (estimated != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.careEstimatedNext(DateFormat.MMMd().format(estimated.date)),
                  key: const Key('care_item_estimated_next'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (!stack && leading != null && !widget.muted) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: Key('care_item_mark_done_${leading.id}'),
                onPressed: _busy
                    ? null
                    : () => ref.read(careCompletionFlowProvider).done(
                          context,
                          schedule: _s,
                          occurrence: leading,
                          onChanged: _refresh,
                          source: CareCommandSource.careItem,
                        ),
                child: Text(l.careMarkDoneLabel(_s.name)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: Key('care_item_occurrence_reschedule_${leading.id}'),
                onPressed: () => PetEventOccurrenceActions.changeDate(
                  context,
                  ref,
                  widget.entry,
                  HealthOccurrence(
                    id: leading.id,
                    entryId: widget.entry.id,
                    scheduledDate: leading.date,
                    scheduledTime: leading.time,
                    status: 'pending',
                  ),
                ),
                child: Text(l.rescheduleActionLabel),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: CareOccurrenceMenu(
                  occurrence: leading,
                  muted: _busy,
                  onSelected: (action) => _occurrenceMenuAction(
                    context,
                    ref,
                    leading,
                    action,
                  ),
                ),
              ),
            ],
            if (stack && !widget.muted) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('care_item_mark_all_done'),
                onPressed: _busy ? null : () => _bulk(done: true),
                child: Text(l.careMarkAllDone),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('care_item_skip_all'),
                onPressed: _busy ? null : () => _bulk(done: false),
                child: Text(l.careSkipAll),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One open occurrence: opens its screen; the tick follows the Done rule.
class _OccurrenceLine extends ConsumerWidget {
  const _OccurrenceLine({
    required this.entry,
    required this.schedule,
    required this.occurrence,
    required this.muted,
    required this.onChanged,
  });

  final HealthEntry entry;
  final CareItemSchedule schedule;
  final OpenOccurrence occurrence;
  final bool muted;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final status = liveStatus(occurrence, schedule.asOf);
    final (label, tone) = switch (status) {
      CareOccurrenceStatus.overdue => (
        l.urgencyOverdue,
        CareItemStatusTone.overdue,
      ),
      CareOccurrenceStatus.notRecorded => (
        l.careStatusNotRecorded,
        CareItemStatusTone.notRecorded,
      ),
      CareOccurrenceStatus.due => (l.careStatusDue, CareItemStatusTone.due),
      _ => (l.careStatusComingUp, CareItemStatusTone.neutral),
    };
    final when = [
      DateFormat.yMMMd().format(occurrence.date),
      ?occurrence.time,
    ].join(' · ');
    return Semantics(
      identifier: 'care_item_occurrence_row_${occurrence.id}',
      label: '$when, $label. ${l.careRowOpensDate}',
      button: true,
      child: InkWell(
        key: Key('care_item_occurrence_${occurrence.id}'),
        onTap: () => openOccurrenceScreen(
          context,
          petId: entry.petId,
          entryId: entry.id,
          occurrenceId: occurrence.id,
          source: 'care_item',
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(child: ExcludeSemantics(child: Text(when))),
              ExcludeSemantics(
                child: CareItemStatusPill(label: label, tone: tone),
              ),
              const SizedBox(width: 8),
              CareMarkDoneButton(
                key: Key('care_item_occurrence_done_${occurrence.id}'),
                semanticLabel: l.careMarkDoneLabel(entry.name),
                onPressed: muted
                    ? null
                    : () => ref
                          .read(careCompletionFlowProvider)
                          .done(
                            context,
                            schedule: schedule,
                            occurrence: occurrence,
                            onChanged: onChanged,
                            source: CareCommandSource.careItem,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
