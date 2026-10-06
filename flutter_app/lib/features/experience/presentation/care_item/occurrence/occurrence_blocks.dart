import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/providers/analytics_providers.dart';
import 'package:pet_profile_app/core/utils/calendar_date_picker.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';

import 'occurrence_undo_label.dart';

/// Primary and secondary actions for one occurrence (§18.6.4): open →
/// required inputs, "When was this done?", Done, Skip, Change date;
/// completed → change when it was done (D-CSM-034) and Undo; closed →
/// Record as done.
class OccurrenceBlocks extends ConsumerStatefulWidget {
  const OccurrenceBlocks({
    super.key,
    required this.detail,
    required this.onChanged,
    this.focus,
  });

  final OccurrenceDetail detail;
  final Future<void> Function() onChanged;
  final String? focus;

  @override
  ConsumerState<OccurrenceBlocks> createState() => _OccurrenceBlocksState();
}

class _OccurrenceBlocksState extends ConsumerState<OccurrenceBlocks> {
  final _weight = TextEditingController();
  late DateTime _date;
  bool _busy = false;

  OccurrenceDetail get _d => widget.detail;
  CareOccurrence get _occ => _d.occurrence;

  @override
  void initState() {
    super.initState();
    _date = _occ.completedOn ?? _d.item.asOf.date;
    _weight.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  CompletionInputs get _inputs {
    final pref = ref.read(weightUnitPreferenceProvider);
    return CompletionInputs(
      weightValue: double.tryParse(_weight.text.replaceAll(',', '.')),
      weightUnit: weightUnitToWire(pref),
    );
  }

  /// Server schedule when available; otherwise a single-slot fallback for tests.
  CareItemSchedule get _schedule {
    final fromServer = _d.schedule;
    if (fromServer != null) return fromServer;
    final open = OpenOccurrence(
      id: _occ.id,
      date: _occ.date,
      time: _occ.time,
      status: _occ.status,
      origin: _occ.origin,
    );
    return CareItemSchedule(
      entryId: _d.item.id,
      petId: _d.item.petId,
      name: _d.item.name,
      careFamily: _d.item.careFamily,
      isFixedSchedule: _d.item.isFixedSchedule,
      status: _d.item.status,
      openOccurrences: [open],
      asOf: _d.item.asOf,
      lateCompletionChoice: _d.item.lateCompletionChoice,
    );
  }

  OpenOccurrence get _targetOccurrence {
    final id = _occ.id;
    return _schedule.openOccurrences.firstWhere(
      (o) => o.id == id,
      orElse: () => OpenOccurrence(
        id: _occ.id,
        date: _occ.date,
        time: _occ.time,
        status: _occ.status,
        origin: _occ.origin,
      ),
    );
  }

  Future<DateTime?> _pick({DateTime? first, DateTime? last}) {
    final today = _d.item.asOf.date;
    return showCalendarDatePicker(
      context: context,
      initialDate: _date,
      firstDate: first ?? DateTime(2000),
      lastDate: last ?? today,
    );
  }

  Future<void> _guard(Future<void> Function() run) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await run();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _report(
    CareOutcome<CareCommandResult> outcome,
    String success,
  ) async {
    final l = AppLocalizations.of(context)!;
    await widget.onChanged();
    if (!mounted) return;
    switch (outcome) {
      case CareSucceeded():
        refreshWeightAfterWeighInCommand(
          ref,
          careFamily: _d.item.careFamily,
          petId: _d.item.petId,
        );
        _snack(success);
      case CareFailed(failure: CareNotOpenFailure()):
        _snack(l.careAlreadyUpdated);
      case CareFailed(failure: CareValidationFailure(:final code)):
        _snack(
          code == 'completed_on_in_future'
              ? l.careCompletedOnFuture
              : l.careCommandFailed,
        );
      case CareFailed():
        _snack(l.careCommandFailed);
    }
  }

  CareCompletionService get _service => ref.read(careCompletionServiceProvider);

  Future<void> _done() => _guard(
    () => ref
        .read(careCompletionFlowProvider)
        .done(
          context,
          schedule: _schedule,
          occurrence: _targetOccurrence,
          onChanged: widget.onChanged,
          source: CareCommandSource.occurrence,
          onOccurrenceScreen: true,
          inputs: _inputs,
          completedOn: _date,
        ),
  );

  @override
  Widget build(BuildContext context) {
    if (_occ.isOpen) return _open(context);
    if (_occ.isDone) return _completed(context);
    if (_occ.isClosedNotRecorded) return _closedNotRecorded(context);
    return _closedSkipped(context);
  }

  Widget _dateField(BuildContext context, {required VoidCallback onTap}) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      key: const Key('occurrence_field_completed_on'),
      contentPadding: EdgeInsets.zero,
      title: Text(l.careCompletedOnLabel),
      subtitle: Text(DateFormat.yMMMd().format(_date)),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: _busy ? null : onTap,
    );
  }

  Widget _open(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final needsWeight = completionRequirementsFor(
      _d.item.careFamily,
    ).contains(CompletionRequirement.weight);
    final missing = missingRequirements(_d.item.careFamily, _inputs);
    final weightUnit = ref.watch(weightUnitPreferenceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.occurrenceActionsSectionTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        if (needsWeight) ...[
          TextField(
            key: const Key('occurrence_field_weight'),
            controller: _weight,
            autofocus: widget.focus == 'weight',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.careWeightFieldLabelUnit(unitLabel(weightUnit)),
              helperText: missing.isEmpty ? null : l.careWeightRequiredHint,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _dateField(
          context,
          onTap: () async {
            final picked = await _pick();
            if (picked != null) setState(() => _date = picked);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const Key('occurrence_done'),
                onPressed: _busy || missing.isNotEmpty ? null : _done,
                child: Text(l.careMarkDoneLabel(_d.item.name)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: const Key('occurrence_skip'),
                onPressed: _busy
                    ? null
                    : () => _guard(() async {
                        if (_d.item.careFamily == kWeightMonitoringFamily) {
                          final skip = await showSkipWeighInSheet(context);
                          if (skip == null) return;
                          final outcome = await _service.skip(
                            entryId: _d.item.id,
                            occurrenceId: _occ.id,
                            reasonCode: skip.reasonCode,
                            notes: skip.notes,
                          );
                          await ref.read(analyticsServiceProvider).capture(
                            'weigh_in_skipped',
                            {'reason_code': skip.reasonCode ?? ''},
                          );
                          await _report(outcome, l.careSkipped(_d.item.name));
                          return;
                        }
                        final outcome = await _service.skip(
                          entryId: _d.item.id,
                          occurrenceId: _occ.id,
                        );
                        await _report(outcome, l.careSkipped(_d.item.name));
                      }),
                child: Text(l.careSkip),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _completed(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final weight = _d.linkedWeight;
    final displayUnit = ref.watch(weightUnitPreferenceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (weight != null) ...[
          ListTile(
            key: const Key('occurrence_linked_weight'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.weight),
            subtitle: Text(
              [
                formatWeight(weight.value, displayUnit),
                if (weight.date != null)
                  l.weightRecordedOn(DateFormat.yMMMd().format(weight.date!)),
              ].join(' · '),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('occurrence_see_all_weights'),
              onPressed: () => context.push('/pet/${_d.item.petId}/weight'),
              child: Text(l.weightSeeAll),
            ),
          ),
        ],
        _dateField(
          context,
          onTap: () => _guard(() async {
            final picked = await _pick();
            if (picked == null || picked == _occ.completedOn) return;
            final outcome = await _service.changeCompletionDate(
              entryId: _d.item.id,
              occurrenceId: _occ.id,
              completedOn: picked,
            );
            if (outcome is CareSucceeded) {
              ref
                  .read(analyticsServiceProvider)
                  .capture('care_completion_date_changed', const {});
            }
            await _report(outcome, l.careDateSaved);
          }),
        ),
        if (_d.canUndoHere)
          OutlinedButton(
            key: const Key('occurrence_undo'),
            onPressed: _busy
                ? null
                : () => _guard(() async {
                    final outcome = await _service.undo(entryId: _d.item.id);
                    await _report(outcome, l.snackbarUndo);
                  }),
            child: Text(occurrenceUndoLabel(l, _d.lastAction)),
          )
        else if (_seriesFinished)
          Text(
            l.occurrenceCareFinishedNoReopen,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  bool get _seriesFinished {
    if (_d.item.status == 'completed') return true;
    return _d.schedule?.status == 'completed';
  }

  Widget _closedNotRecorded(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: closedNotRecordedSemantics(l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.careClosedNotRecordedBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('occurrence_record'),
            onPressed: _busy
                ? null
                : () => _guard(() async {
                    final picked = await showRecordAsGivenSheet(
                      context,
                      occurrence: _occ,
                      today: _d.item.asOf.date,
                    );
                    if (picked == null) return;
                    final outcome = await _service.recordAsDone(
                      entryId: _d.item.id,
                      occurrenceId: _occ.id,
                      completedOn: picked,
                    );
                    await _report(outcome, l.careRecorded(_d.item.name));
                  }),
            child: Text(l.careRecordAsDone),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('occurrence_confirm_skip'),
            onPressed: _busy
                ? null
                : () => _guard(() async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l.careConfirmSkipTitle),
                        content: Text(l.careConfirmSkipBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l.cancel),
                          ),
                          FilledButton(
                            key: const Key('occurrence_confirm_skip_ok'),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l.careConfirmSkipAction),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    final outcome = await _service.confirmSkip(
                      entryId: _d.item.id,
                      occurrenceId: _occ.id,
                    );
                    await _report(outcome, l.careSkipped(_d.item.name));
                  }),
            child: Text(l.careConfirmSkipAction),
          ),
        ],
      ),
    );
  }

  Widget _closedSkipped(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final skip = _d.skipReason;
    final isWeighIn = _d.item.careFamily == kWeightMonitoringFamily;
    final reasonLabel = isWeighIn
        ? weighInSkipReasonLabel(l, skip?.code)
        : null;
    final text = reasonLabel != null
        ? l.careSkippedWithReason(reasonLabel)
        : l.careSkipped(_d.item.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          key: const Key('occurrence_skipped_status'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (isWeighIn && skip?.note != null && skip!.note!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            skip.note!,
            key: const Key('occurrence_skipped_note'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_d.canUndoHere) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('occurrence_undo'),
            onPressed: _busy
                ? null
                : () => _guard(() async {
                    final outcome = await _service.undo(entryId: _d.item.id);
                    await _report(outcome, l.snackbarUndo);
                  }),
            child: Text(occurrenceUndoLabel(l, _d.lastAction)),
          ),
        ] else if (_seriesFinished) ...[
          const SizedBox(height: 8),
          Text(
            l.occurrenceCareFinishedNoReopen,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
