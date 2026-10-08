import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/analytics_providers.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'occurrence_closed_actions.dart';
import 'occurrence_open_actions.dart';

/// Completion module: Mark as done (open) or record/undo bodies (closed).
class OccurrenceCompleteCareModule extends ConsumerStatefulWidget {
  const OccurrenceCompleteCareModule({
    super.key,
    required this.detail,
    required this.onChanged,
    this.focus,
    this.actionBusy = false,
  });

  final OccurrenceDetail detail;
  final Future<void> Function() onChanged;
  final String? focus;
  final bool actionBusy;

  @override
  ConsumerState<OccurrenceCompleteCareModule> createState() =>
      _OccurrenceCompleteCareModuleState();
}

class _OccurrenceCompleteCareModuleState
    extends ConsumerState<OccurrenceCompleteCareModule> {
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

  CompletionInputs get _inputs {
    final pref = ref.read(weightUnitPreferenceProvider);
    return CompletionInputs(
      weightValue: double.tryParse(_weight.text.replaceAll(',', '.')),
      weightUnit: weightUnitToWire(pref),
    );
  }

  bool get _seriesFinished {
    if (_d.item.status == 'completed') return true;
    return _d.schedule?.status == 'completed';
  }

  bool get _actionBusy => _busy || widget.actionBusy;

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

  Future<void> _confirmSkipClosed() => _guard(() async {
    final l = AppLocalizations.of(context)!;
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
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isOpen = _occ.isOpen;

    return CareItemModule(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOpen)
            OccurrenceOpenActions(
              detail: _d,
              weightController: _weight,
              focus: widget.focus,
              busy: _actionBusy,
              onDone: _done,
            )
          else
            OccurrenceClosedActions(
              detail: _d,
              date: _date,
              busy: _actionBusy,
              seriesFinished: _seriesFinished,
              onDateChange: (picked) => _guard(() async {
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
              onUndo: () => _guard(() async {
                final outcome = await _service.undo(entryId: _d.item.id);
                await _report(outcome, l.snackbarUndo);
              }),
              onRecord: (picked) => _guard(() async {
                final outcome = await _service.recordAsDone(
                  entryId: _d.item.id,
                  occurrenceId: _occ.id,
                  completedOn: picked,
                );
                await _report(outcome, l.careRecorded(_d.item.name));
              }),
              onConfirmSkip: _confirmSkipClosed,
            ),
        ],
      ),
    );
  }
}
