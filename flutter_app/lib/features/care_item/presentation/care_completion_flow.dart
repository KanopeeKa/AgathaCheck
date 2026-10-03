import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/analytics_providers.dart';
import '../../../core/router/shell_return_navigation.dart';
import '../../../l10n/app_localizations.dart';
import '../application/care_command_outcome.dart';
import '../application/care_completion_service.dart';
import '../application/care_item_providers.dart';
import '../domain/care_item_schedule.dart';
import '../domain/care_occurrence.dart';
import '../domain/completion_requirements.dart';
import '../domain/done_decision.dart';
import '../domain/leading_occurrence.dart';
import 'sheets/completion_date_sheet.dart';
import 'sheets/early_completion_dialog.dart';

/// Reports what a command changed so the caller refreshes its data.
typedef CareChanged = Future<void> Function();

/// The only entry point for Done (§18.8). Applies [decideDone], opens at most
/// one modal (SH-1), sends one request, and shows the server-confirmed
/// result with Undo (UIR-2). Nothing changes on screen before the server
/// answers.
class CareCompletionFlow {
  CareCompletionFlow(
    this._service, {
    void Function(String, Map<String, Object>)? track,
  }) : _track = track ?? ((_, _) {});

  final CareCompletionService _service;
  final void Function(String event, Map<String, Object> properties) _track;

  /// Entries with a request in flight (double taps are ignored).
  static final Set<String> _busy = {};

  static bool isBusy(String entryId) => _busy.contains(entryId);

  Future<void> done(
    BuildContext context, {
    required CareItemSchedule schedule,
    required CareChanged onChanged,
    required CareCommandSource source,
    OpenOccurrence? occurrence,
    bool onOccurrenceScreen = false,
    CompletionInputs inputs = const CompletionInputs(),
    DateTime? completedOn,
  }) async {
    if (_busy.contains(schedule.entryId)) return;
    final props = <String, Object>{
      'surface': source.name,
      'family': schedule.careFamily ?? 'unknown',
      'schedule_type': schedule.isFixedSchedule ? 'fixed' : 'after_done',
    };
    _track('care_done_tapped', props);

    final decision = decideDone(
      schedule,
      occurrence: occurrence,
      onOccurrenceScreen: onOccurrenceScreen,
    );
    var path = onOccurrenceScreen
        ? CareCommandPath.occurrenceScreen
        : CareCommandPath.oneTap;
    DateTime? date = completedOn;
    OpenOccurrence target;
    var offerChangeDate = false;
    switch (decision) {
      case DoneOpensCareItem():
        openPetEventView(
          context,
          petId: schedule.petId,
          entryId: schedule.entryId,
        );
        return;
      case DoneOpensOccurrence(:final occurrence, :final requirement):
        openOccurrenceScreen(
          context,
          petId: schedule.petId,
          entryId: schedule.entryId,
          occurrenceId: occurrence.id,
          focus: requirement.name,
        );
        return;
      case DoneAsksDate(:final occurrence):
        date = await showCompletionDateSheet(
          context,
          occurrence: occurrence,
          asOf: schedule.asOf,
        );
        if (date == null) return;
        target = occurrence;
        path = CareCommandPath.dateSheet;
      case DoneConfirmsEarly(:final occurrence):
        if (!await showEarlyCompletionDialog(
          context,
          plannedFor: occurrence.date,
        )) {
          return;
        }
        target = occurrence;
        path = CareCommandPath.earlyDialog;
      case DoneCompletesToday(:final occurrence, offerChangeDate: final offer):
        target = occurrence;
        offerChangeDate = offer;
    }
    if (!context.mounted) return;

    final started = DateTime.now();
    _busy.add(schedule.entryId);
    final CareOutcome<CareCommandResult> outcome;
    try {
      outcome = await _service.complete(
        CareCompletionRequest(
          petId: schedule.petId,
          entryId: schedule.entryId,
          occurrenceId: target.id,
          careFamily: schedule.careFamily,
          completedOn: date ?? schedule.asOf.date,
          inputs: inputs,
          source: source,
          path: path,
        ),
      );
    } finally {
      _busy.remove(schedule.entryId);
    }
    await onChanged();
    if (!context.mounted) return;

    switch (outcome) {
      case CareSucceeded(:final value):
        _track('care_done_succeeded', {
          ...props,
          'status_before': target.status.name,
          'latency': _latencyBucket(DateTime.now().difference(started)),
        });
        _showDone(
          context,
          schedule: schedule,
          result: value,
          onChanged: onChanged,
          changeDateOccurrenceId: offerChangeDate ? target.id : null,
        );
      case CareFailed(:final failure):
        _track('care_done_failed', {
          ...props,
          'reason': failure.analyticsValue,
        });
        _showFailure(
          context,
          failure,
          retry: () => done(
            context,
            schedule: schedule,
            onChanged: onChanged,
            source: source,
            occurrence: target,
            onOccurrenceScreen: true,
            inputs: inputs,
            completedOn: date,
          ),
        );
    }
  }

  void _showDone(
    BuildContext context, {
    required CareItemSchedule schedule,
    required CareCommandResult result,
    required CareChanged onChanged,
    String? changeDateOccurrenceId,
  }) {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final next = result.schedule == null
        ? null
        : leadingOccurrence(result.schedule!);
    String? second;
    String? changeOccurrenceId = changeDateOccurrenceId;
    if (next != null) {
      final when = next.date == schedule.asOf.date && next.time != null
          ? next.time!
          : DateFormat.MMMd().format(next.date);
      if (result.nextChoiceApplied != null) {
        second = l.careNextStays(when);
        changeOccurrenceId ??= next.id;
      } else {
        second = l.careNextDate(when);
      }
    }
    final undoToken = result.undoToken;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('care_done_snackbar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.careDoneSnackbar(schedule.name)),
            if (second != null) Text(second),
            if (changeOccurrenceId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('care_done_change_date'),
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    openOccurrenceScreen(
                      context,
                      petId: schedule.petId,
                      entryId: schedule.entryId,
                      occurrenceId: changeOccurrenceId!,
                      focus: 'date',
                    );
                  },
                  child: Text(l.careChangeDate),
                ),
              ),
          ],
        ),
        action: undoToken == null
            ? null
            : SnackBarAction(
                key: const Key('care_done_undo'),
                label: l.snackbarUndo,
                onPressed: () async {
                  final undone = await _service.undo(
                    entryId: schedule.entryId,
                    undoToken: undoToken,
                  );
                  if (undone is CareSucceeded) {
                    _track('care_done_undone', {
                      'family': schedule.careFamily ?? 'unknown',
                    });
                  }
                  await onChanged();
                },
              ),
      ),
    );
  }

  void _showFailure(
    BuildContext context,
    CareCommandFailure failure, {
    required VoidCallback retry,
  }) {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (failure is CareNotOpenFailure) {
      messenger.showSnackBar(
        SnackBar(
          key: const Key('care_already_updated'),
          content: Text(l.careAlreadyUpdated),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        key: const Key('care_done_failed'),
        content: Text(l.careCommandFailed),
        action: SnackBarAction(label: l.careRetry, onPressed: retry),
      ),
    );
  }

  static String _latencyBucket(Duration d) {
    final ms = d.inMilliseconds;
    if (ms < 300) return 'lt_300ms';
    if (ms < 1000) return 'lt_1s';
    if (ms < 3000) return 'lt_3s';
    return 'gte_3s';
  }
}

final careCompletionFlowProvider = Provider<CareCompletionFlow>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return CareCompletionFlow(
    ref.watch(careCompletionServiceProvider),
    track: (event, properties) => analytics.capture(event, properties),
  );
});
