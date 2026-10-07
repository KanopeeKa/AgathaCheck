import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../../core/widgets/form/app_form_breakpoints.dart';
import '../../../../../core/widgets/form/app_form_destructive_button.dart';
import '../../../../../core/widgets/form/app_form_discard_dialog.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/datasources/care_context_remote_datasource.dart';
import '../planned_absence_date_rules.dart';
import '../providers/care_context_providers.dart';
import '../widgets/away_plan_handover_note_editor.dart';
import '../widgets/planned_absence_dates_step.dart';

/// Full-screen trip details form: title, dates, notes, and cancel plan.
class PlannedAbsenceEditScreen extends ConsumerStatefulWidget {
  const PlannedAbsenceEditScreen({super.key, required this.absenceId});

  final String absenceId;

  @override
  ConsumerState<PlannedAbsenceEditScreen> createState() =>
      _PlannedAbsenceEditScreenState();
}

class _PlannedAbsenceEditScreenState
    extends ConsumerState<PlannedAbsenceEditScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _startsOn;
  DateTime? _endsOn;
  String? _baselineTitle;
  String? _baselineStartsOn;
  String? _baselineEndsOn;
  String? _baselineNote;
  String? _stepValidationMessage;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChanged);
    _noteController.addListener(_onFieldChanged);
    _loadAbsence();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  bool get _isBusy => _isSaving || _isDeleting;

  bool get _isDirty {
    if (_baselineStartsOn == null) return false;
    final title = _titleController.text.trim();
    final baselineTitle = (_baselineTitle ?? '').trim();
    final note = _noteController.text.trim();
    final baselineNote = (_baselineNote ?? '').trim();
    return title != baselineTitle ||
        note != baselineNote ||
        PlannedAbsenceDateRules.startsOnWire(_startsOn) != _baselineStartsOn ||
        PlannedAbsenceDateRules.endsOnWire(_endsOn) != _baselineEndsOn;
  }

  Future<void> _loadAbsence() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final absence = await ref
          .read(careContextRepositoryProvider)
          .getPlannedAbsence(widget.absenceId);
      if (!mounted) return;
      _titleController.text = absence.title ?? '';
      _noteController.text = absence.handoverNote ?? '';
      _startsOn = _parseWireDate(absence.startsOn);
      _endsOn = _parseWireDate(absence.endsOn);
      _baselineTitle = absence.title;
      _baselineStartsOn = absence.startsOn;
      _baselineEndsOn = absence.endsOn;
      _baselineNote = absence.handoverNote;
    } catch (_) {
      if (mounted) _loadFailed = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime? _parseWireDate(String wire) {
    final parts = wire.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  void _goToPlan() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final returnTo = shellReturnToFromState(GoRouterState.of(context));
    context.go(awayPlanDetailLocation(widget.absenceId, returnTo: returnTo));
  }

  Future<void> _handleBack() async {
    if (!_isDirty) {
      _goToPlan();
      return;
    }
    if (await confirmDiscardFormChanges(context) && mounted) {
      _goToPlan();
    }
  }

  bool _validateDates(AppLocalizations l) {
    if (!PlannedAbsenceDateRules.isValidRange(_startsOn, _endsOn)) {
      if (_startsOn == null || _endsOn == null) {
        _stepValidationMessage = l.careContextAwayDatesRequired;
      } else if (_endsOn!.isBefore(_startsOn!)) {
        _stepValidationMessage = l.careContextAwayDatesInvalid;
      } else {
        _stepValidationMessage = l.careContextAwayDatesHorizon;
      }
      return false;
    }
    _stepValidationMessage = null;
    return true;
  }

  Future<bool> _confirmDateChange(AppLocalizations l) async {
    final startsOn = PlannedAbsenceDateRules.startsOnWire(_startsOn);
    final endsOn = PlannedAbsenceDateRules.endsOnWire(_endsOn);
    if (startsOn == _baselineStartsOn && endsOn == _baselineEndsOn) {
      return true;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.careContextAwayDateChangeConfirmTitle),
        content: Text(l.careContextAwayDateChangeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.careContextAwayContinue),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmGuestWiden(AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.careContextAwayGuestWidenConfirmTitle),
        content: Text(l.careContextAwayGuestWidenConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.careContextAwayContinue),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _save({bool confirmGuestAccessWiden = false}) async {
    final l = AppLocalizations.of(context)!;
    if (!_validateDates(l)) {
      setState(() {});
      return;
    }
    if (!confirmGuestAccessWiden && !await _confirmDateChange(l)) return;

    final startsOn = PlannedAbsenceDateRules.startsOnWire(_startsOn)!;
    final endsOn = PlannedAbsenceDateRules.endsOnWire(_endsOn)!;
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();

    setState(() => _isSaving = true);
    try {
      await ref
          .read(careContextRepositoryProvider)
          .updatePlannedAbsenceDetails(
            absenceId: widget.absenceId,
            startsOn: startsOn,
            endsOn: endsOn,
            title: title.isEmpty ? null : title,
            handoverNote: note.isEmpty ? null : note,
            confirmGuestAccessWiden: confirmGuestAccessWiden,
          );
      ref.invalidate(plannedAbsenceDetailProvider(widget.absenceId));
      ref.invalidate(awayPlanReadinessProvider(widget.absenceId));
      ref.invalidate(plannedAbsencesListProvider);
      ref.invalidate(awayPlanningDashboardTileProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveSuccess)));
        _goToPlan();
      }
    } on CareContextApiException catch (e) {
      if (e.code == 'guest_access_widen_required' && mounted) {
        if (await _confirmGuestWiden(l)) {
          await _save(confirmGuestAccessWiden: true);
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveFailed)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete(AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.careContextAwayEditDeleteTitle),
        content: Text(l.careContextAwayEditDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('away_plan_edit_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref
          .read(careContextRepositoryProvider)
          .cancelPlannedAbsence(widget.absenceId);
      ref.invalidate(plannedAbsencesListProvider);
      ref.invalidate(plannedAbsenceDetailProvider(widget.absenceId));
      ref.invalidate(awayPlanReadinessProvider(widget.absenceId));
      ref.invalidate(awayPlanningDashboardTileProvider);
      if (mounted) context.goNamed('petCarePlannedAbsence');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.careContextAwayEditDeleteFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _actionsBar(AppLocalizations l) {
    return AppFormActionsBar(
      isLoading: _isBusy,
      isDirty: _isDirty,
      onSave: _save,
      onCancel: _handleBack,
      saveLabel: l.careContextAwaySaveAction,
      cancelKey: const Key('away_plan_edit_cancel'),
      saveKey: const Key('away_plan_edit_save'),
    );
  }

  Widget _formContent(AppLocalizations l, {required bool includeActions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('away_plan_trip_title'),
          controller: _titleController,
          decoration: InputDecoration(
            labelText: l.careContextAwayTitleLabel,
            hintText: l.careContextAwayTitleHint,
            helperText: l.careContextAwayTitleHelper,
          ),
          maxLength: 60,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        PlannedAbsenceDatesStep(
          startsOn: _startsOn,
          endsOn: _endsOn,
          validationMessage: _stepValidationMessage,
          onRangeChanged: (start, end) => setState(() {
            _startsOn = start;
            _endsOn = end;
            _stepValidationMessage = null;
          }),
        ),
        const SizedBox(height: 16),
        AwayPlanHandoverNoteEditor(controller: _noteController),
        const SizedBox(height: 24),
        AppFormDestructiveButton(
          buttonKey: const Key('away_plan_edit_delete'),
          label: l.careContextAwayEditDeleteAction,
          onPressed: _isBusy ? null : () => _confirmDelete(l),
        ),
        if (includeActions) ...[const SizedBox(height: 24), _actionsBar(l)],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isPhone =
        AppFormBreakpoints.layoutForWidth(MediaQuery.sizeOf(context).width) ==
        AppFormLayoutSize.phone;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmDiscardFormChanges(context) && context.mounted) {
          _goToPlan();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: l.careContextAwayTripDetailsTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l.goBack,
            onPressed: _handleBack,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
            ? Center(child: Text(l.careContextAwayPlanLoadError))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final layout = AppFormBreakpoints.layoutForWidth(
                    constraints.maxWidth,
                  );
                  final includeActions = layout != AppFormLayoutSize.phone;
                  final form = _formContent(l, includeActions: includeActions);
                  if (layout == AppFormLayoutSize.phone) {
                    return SingleChildScrollView(
                      key: const Key('away_plan_edit_page'),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      child: form,
                    );
                  }
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      key: const Key('away_plan_edit_page'),
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppFormBreakpoints.tabletContentMaxWidth,
                        ),
                        child: form,
                      ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: isPhone && !_isLoading && !_loadFailed
            ? AppFormStickyActionsBar(
                stickyKey: const Key('away_plan_edit_sticky_actions'),
                isLoading: _isBusy,
                isDirty: _isDirty,
                onSave: _save,
                onCancel: _handleBack,
                saveLabel: l.careContextAwaySaveAction,
                cancelKey: const Key('away_plan_edit_cancel'),
                saveKey: const Key('away_plan_edit_save'),
              )
            : null,
      ),
    );
  }
}
