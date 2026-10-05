import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import '../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/weight_api_exception.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/entities/weight_fulfilment_candidates.dart';
import '../../domain/entities/weight_write_outcomes.dart';
import '../providers/weight_providers.dart';
import 'record_weight_counts_as_section.dart';

Future<void> showRecordWeightSheet(
  BuildContext context,
  WidgetRef ref, {
  required String petId,
  WeightEntry? editing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _RecordWeightSheetBody(petId: petId, editing: editing),
  );
}

class _RecordWeightSheetBody extends ConsumerStatefulWidget {
  const _RecordWeightSheetBody({required this.petId, this.editing});

  final String petId;
  final WeightEntry? editing;

  @override
  ConsumerState<_RecordWeightSheetBody> createState() =>
      _RecordWeightSheetBodyState();
}

class _RecordWeightSheetBodyState
    extends ConsumerState<_RecordWeightSheetBody> {
  late DateTime _selectedDate;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;
  String? _weightError;
  String? _fulfilmentError;
  bool _switchOn = true;
  String? _radioSelection;
  bool _checkTimedOut = false;
  bool _showEditFulfilChoice = false;
  bool _saving = false;
  Timer? _checkTimer;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = calendarDateOnly(widget.editing?.date ?? DateTime.now());
    final unit = ref.read(weightUnitPreferenceProvider);
    _weightController = TextEditingController(
      text: widget.editing != null
          ? toDisplay(widget.editing!.weight, unit).toStringAsFixed(1)
          : '',
    );
    _notesController = TextEditingController(text: widget.editing?.notes ?? '');
    _startCheckTimer();
  }

  void _startCheckTimer() {
    _checkTimer?.cancel();
    if (_isEdit) return;
    _checkTimedOut = false;
    _checkTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _checkTimedOut = true);
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  WeightFulfilmentQuery _query() => (petId: widget.petId, date: _selectedDate);

  bool _saveEnabled(AsyncValue<WeightFulfilmentCandidates>? candidatesAsync) {
    if (_saving || _weightError != null) return false;
    if (_weightController.text.trim().isEmpty) return false;
    if (_isEdit) return true;

    final async = candidatesAsync;
    if (async == null) return true;
    if (async.isLoading && !_checkTimedOut) return false;

    return async.when(
      loading: () => _checkTimedOut,
      error: (_, __) => true,
      data: (data) {
        if (data.candidates.isEmpty) return true;
        if (data.candidates.length == 1) return true;
        return _radioSelection != null;
      },
    );
  }

  String? _fulfilsOccurrenceId(WeightFulfilmentCandidates? data) {
    if (_isEdit || data == null) return null;
    if (data.candidates.isEmpty) return null;
    if (data.candidates.length == 1) {
      return _switchOn ? data.candidates.first.occurrenceId : null;
    }
    return RecordWeightCountsAsSection.occurrenceIdForSave(_radioSelection);
  }

  double? _parseWeightKg() {
    final raw = _weightController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      setState(() => _weightError = 'invalid');
      return null;
    }
    final unit = ref.read(weightUnitPreferenceProvider);
    return toKg(value, unit);
  }

  Future<void> _save() async {
    if (!_saveEnabled(_createCandidates)) return;
    final l = AppLocalizations.of(context)!;
    final kg = _parseWeightKg();
    if (kg == null) return;

    setState(() => _saving = true);
    final fulfilsId = _fulfilsOccurrenceId(_createCandidates?.valueOrNull);

    final entry = WeightEntry(
      id: widget.editing?.id ?? const Uuid().v4(),
      petId: widget.petId,
      date: _selectedDate,
      weight: kg,
      notes: _notesController.text.trim(),
      measurementSource: widget.editing?.measurementSource ?? 'guardian',
      fulfils: widget.editing?.fulfils,
    );

    try {
      final outcome = await ref
          .read(weightEntriesNotifierProvider(widget.petId).notifier)
          .saveEntry(entry: entry, fulfilsOccurrenceId: fulfilsId);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      _showSaveSnackBar(messenger, l, outcome);
    } on WeightApiException catch (e) {
      if (e.code == 'fulfilment_not_eligible') {
        setState(() {
          _fulfilmentError = l.weightFulfilmentStale;
          _saving = false;
        });
        ref.invalidate(weightFulfilmentCandidatesProvider(_query()));
        return;
      }
      if (e.code == 'date_in_future' || e.code == 'completed_on_in_future') {
        setState(() {
          _weightError = l.weightDateInFuture;
          _saving = false;
        });
        return;
      }
      if (e.code == 'completed_on_before_start') {
        setState(() {
          _weightError = l.weightDateBeforeRoutineStart;
          _saving = false;
        });
        return;
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _fulfilExisting(WeightFulfilmentCandidates data) async {
    final l = AppLocalizations.of(context)!;
    final occurrenceId = data.candidates.length == 1
        ? (_switchOn ? data.candidates.first.occurrenceId : null)
        : RecordWeightCountsAsSection.occurrenceIdForSave(_radioSelection);
    if (occurrenceId == null || widget.editing == null) return;

    setState(() => _saving = true);
    try {
      final outcome = await ref
          .read(weightEntriesNotifierProvider(widget.petId).notifier)
          .fulfilExisting(widget.editing!.id, occurrenceId);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      _showSaveSnackBar(messenger, l, outcome);
    } on WeightApiException catch (e) {
      if (e.code == 'fulfilment_not_eligible') {
        setState(() => _fulfilmentError = l.weightFulfilmentStale);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSaveSnackBar(
    ScaffoldMessengerState messenger,
    AppLocalizations l,
    WeightSaveOutcome outcome,
  ) {
    final fulfilment = outcome.fulfilment;
    final routineName =
        fulfilment?.routineName ?? outcome.entry.fulfils?.entryName;

    if (fulfilment != null && routineName != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.weightSavedCountedAs(routineName)),
          action: SnackBarAction(
            label: l.snackbarUndo,
            onPressed: () async {
              await ref
                  .read(weightEntriesNotifierProvider(widget.petId).notifier)
                  .undoFulfilment(
                    careEntryId: fulfilment.careEntryId,
                    undoToken: fulfilment.undoToken,
                  );
              if (context.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l.weightWeighInUndone)),
                );
              }
            },
          ),
        ),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.weightSaved)));
    }
  }

  AsyncValue<WeightFulfilmentCandidates>? get _createCandidates =>
      _isEdit ? null : ref.watch(weightFulfilmentCandidatesProvider(_query()));

  AsyncValue<WeightFulfilmentCandidates>? get _editFulfilCandidates {
    if (!_isEdit || widget.editing!.fulfils != null) return null;
    return ref.watch(weightFulfilmentCandidatesProvider(_query()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitPreferenceProvider);
    final unitStr = unitLabel(unit);
    final createCandidates = _createCandidates;

    final editFulfil = _editFulfilCandidates;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? l.weightEditSheetTitle : l.weightRecordSheetTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.editing?.fulfils != null) ...[
              const SizedBox(height: 12),
              Text(
                l.weightLinkedEditInfo(
                  widget.editing!.fulfils!.entryName,
                  DateFormat.yMMMd().format(
                    calendarDateOnly(widget.editing!.fulfils!.scheduledDate),
                  ),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 20),
            AppFormLabeledField(
              label: l.date,
              isTextField: false,
              child: Semantics(
                label: l.selectDate,
                button: true,
                child: InkWell(
                  key: const Key('record_weight_date'),
                  onTap: () async {
                    final picked = await showCalendarDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: calendarDateOnly(DateTime.now()),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _switchOn = true;
                        _radioSelection = null;
                        _fulfilmentError = null;
                      });
                      _startCheckTimer();
                      ref.invalidate(
                        weightFulfilmentCandidatesProvider(_query()),
                      );
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text(
                      DateFormat.yMMMd().format(
                        calendarDateOnly(_selectedDate),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppFormLabeledField(
              label: l.weightFieldLabelUnit(unitStr),
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  errorText: _weightError != null ? l.weightFormatHint : null,
                ),
                onChanged: (_) => setState(() => _weightError = null),
              ),
            ),
            const SizedBox(height: 16),
            AppFormLabeledField(
              label: l.notesOptional,
              child: TextField(controller: _notesController, maxLines: 2),
            ),
            if (createCandidates != null) ...[
              const SizedBox(height: 16),
              RecordWeightCountsAsSection(
                candidatesAsync: createCandidates,
                selectedOccurrenceId: _radioSelection,
                switchOn: _switchOn,
                onSwitchChanged: (v) => setState(() => _switchOn = v),
                onRadioChanged: (v) => setState(() => _radioSelection = v),
                onRetry: () {
                  _startCheckTimer();
                  ref.invalidate(weightFulfilmentCandidatesProvider(_query()));
                },
              ),
            ],
            if (_fulfilmentError != null) ...[
              const SizedBox(height: 8),
              Text(
                _fulfilmentError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (editFulfil != null &&
                editFulfil.hasValue &&
                (editFulfil.value?.candidates.isNotEmpty ?? false) &&
                !_showEditFulfilChoice) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showEditFulfilChoice = true),
                child: Text(l.weightCountAsWeighInAction),
              ),
            ],
            if (_showEditFulfilChoice && editFulfil != null) ...[
              const SizedBox(height: 8),
              RecordWeightCountsAsSection(
                candidatesAsync: editFulfil,
                selectedOccurrenceId: _radioSelection,
                switchOn: _switchOn,
                onSwitchChanged: (v) => setState(() => _switchOn = v),
                onRadioChanged: (v) => setState(() => _radioSelection = v),
                onRetry: () => ref.invalidate(
                  weightFulfilmentCandidatesProvider(_query()),
                ),
              ),
              FilledButton(
                onPressed: editFulfil.hasValue
                    ? () => _fulfilExisting(editFulfil.value!)
                    : null,
                child: Text(l.weightCountAsWeighInAction),
              ),
            ],
            const SizedBox(height: 16),
            AppFormActionsBar(
              isLoading: _saving || !_saveEnabled(createCandidates),
              isDirty: _weightController.text.trim().isNotEmpty,
              requireDirtyToSave: true,
              onCancel: () => Navigator.pop(context),
              saveLabel: l.save,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}
