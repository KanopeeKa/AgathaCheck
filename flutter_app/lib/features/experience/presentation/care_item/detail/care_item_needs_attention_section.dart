import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/providers/analytics_providers.dart';
import 'package:pet_profile_app/core/widgets/app_undo_snackbar.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/core/widgets/care_mark_done_button.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'care_occurrence_menu.dart';

CareItemStatusTone _pillTone(OccurrencePillTone tone) => switch (tone) {
  OccurrencePillTone.overdue => CareItemStatusTone.overdue,
  OccurrencePillTone.due => CareItemStatusTone.due,
  OccurrencePillTone.closedNotRecorded => CareItemStatusTone.notRecordedClosed,
  OccurrencePillTone.neutral => CareItemStatusTone.neutral,
};

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
          'count': value.stackChangedCount,
          'ignored': value.ignoredIds.length,
          'done': done,
        });
        final message = Text(
          careStackSuccessMessage(
            l,
            done: done,
            result: value,
            itemName: _s.name,
          ),
        );
        if (value.undoToken == null) {
          messenger.showAppSnackBar(
            snackBarKey: const Key('care_stack_snackbar'),
            content: message,
          );
        } else {
          messenger.showUndoSnackBar(
            snackBarKey: const Key('care_stack_snackbar'),
            content: message,
            undoLabel: l.snackbarUndo,
            onUndo: () async {
              await service.undo(
                entryId: _s.entryId,
                undoToken: value.undoToken,
              );
              await _refresh();
            },
          );
        }
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.careCommandFailed)));
        }
      case CareOccurrenceMenuAction.postpone:
        final fixed = _s.isFixedSchedule;
        final paused = await showPostponeSheet(
          context,
          ref,
          entryId: _s.entryId,
          isFixedSchedule: fixed,
        );
        if (paused == true) {
          PetEventOccurrenceActions.invalidateOccurrenceData(ref, _s.entryId);
          await _refresh();
        }
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
                    : () => ref
                          .read(careCompletionFlowProvider)
                          .done(
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
                  onSelected: (action) =>
                      _occurrenceMenuAction(context, ref, leading, action),
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
    final pill = openOccurrencePillStyle(l, status);
    final when = [
      DateFormat.yMMMd().format(occurrence.date),
      ?occurrence.time,
    ].join(' · ');
    return Semantics(
      identifier: 'care_item_occurrence_row_${occurrence.id}',
      label: '$when, ${pill.label}. ${l.careRowOpensDate}',
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
                child: CareItemStatusPill(
                  label: pill.label,
                  tone: _pillTone(pill.tone),
                ),
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
