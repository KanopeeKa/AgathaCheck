import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/analytics_providers.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/care_command_outcome.dart';
import '../../application/care_completion_service.dart';
import '../../application/care_item_providers.dart';
import '../../domain/care_item_schedule.dart';
import '../../domain/care_occurrence.dart';
import '../../domain/completion_requirements.dart';
import '../../domain/occurrence_detail.dart';
import '../care_completion_flow.dart';

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

  CompletionInputs get _inputs => CompletionInputs(
    weightValue: double.tryParse(_weight.text.replaceAll(',', '.')),
  );

  /// The occurrence as an open slot for the Done rule.
  CareItemSchedule get _schedule {
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
        _snack(success);
      case CareFailed(failure: CareNotOpenFailure()):
        _snack(l.careAlreadyUpdated);
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
          occurrence: _schedule.openOccurrences.single,
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
    return _closed(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.careMarkDoneLabel(_d.item.name),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (needsWeight) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('occurrence_field_weight'),
            controller: _weight,
            autofocus: widget.focus == 'weight',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.careWeightFieldLabel,
              helperText: missing.isEmpty ? null : l.careWeightRequiredHint,
            ),
          ),
        ],
        _dateField(
          context,
          onTap: () async {
            final picked = await _pick();
            if (picked != null) setState(() => _date = picked);
          },
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('occurrence_done'),
          onPressed: _busy || missing.isNotEmpty ? null : _done,
          child: Text(l.done),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('occurrence_skip'),
                onPressed: _busy
                    ? null
                    : () => _guard(() async {
                        final outcome = await _service.skip(
                          entryId: _d.item.id,
                          occurrenceId: _occ.id,
                        );
                        await _report(outcome, l.careSkipped(_d.item.name));
                      }),
                child: Text(l.careSkip),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: const Key('occurrence_change_date'),
                onPressed: _busy
                    ? null
                    : () => _guard(() async {
                        final today = _d.item.asOf.date;
                        final picked = await showCalendarDatePicker(
                          context: context,
                          initialDate: _occ.date.isBefore(today)
                              ? today
                              : _occ.date,
                          firstDate: today,
                          lastDate: DateTime(today.year + 5),
                          helpText: l.careNewDateTitle,
                        );
                        if (picked == null) return;
                        final outcome = await _service.changeDate(
                          entryId: _d.item.id,
                          occurrenceId: _occ.id,
                          date: picked,
                        );
                        await _report(outcome, l.careDateMoved);
                      }),
                child: Text(l.careChangeDate),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (weight != null)
          ListTile(
            key: const Key('occurrence_linked_weight'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.weight),
            subtitle: Text('${weight.value} ${weight.unit}'),
          ),
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
            child: Text(
              _d.lastAction!.isCompletionDateChange
                  ? l.careUndoDateChange
                  : l.snackbarUndo,
            ),
          ),
      ],
    );
  }

  Widget _closed(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateField(
          context,
          onTap: () async {
            final picked = await _pick(first: _occ.date);
            if (picked != null) setState(() => _date = picked);
          },
        ),
        FilledButton(
          key: const Key('occurrence_record'),
          onPressed: _busy
              ? null
              : () => _guard(() async {
                  final outcome = await _service.recordAsDone(
                    entryId: _d.item.id,
                    occurrenceId: _occ.id,
                    completedOn: _date,
                  );
                  await _report(outcome, l.careRecorded(_d.item.name));
                }),
          child: Text(l.careRecordAsDone),
        ),
      ],
    );
  }
}
