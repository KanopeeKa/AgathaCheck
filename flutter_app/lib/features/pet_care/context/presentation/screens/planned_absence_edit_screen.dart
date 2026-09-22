import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../../core/widgets/form/app_form_breakpoints.dart';
import '../../../../../core/widgets/form/app_form_destructive_button.dart';
import '../../../../../core/widgets/form/app_form_discard_dialog.dart';
import '../../../../../l10n/app_localizations.dart';
import '../providers/care_context_providers.dart';
import '../widgets/away_plan_handover_note_editor.dart';

/// Edit screen for an away plan's handover note, and the place "Delete"
/// (cancel the whole absence) lives.
///
/// Per D-AWD-007, scope is intentionally narrow: the handover note plus
/// delete. Absence dates/pets and carer assignment are out of scope here —
/// carer assignment stays inline on `PlannedAbsencePlanScreen`, unchanged.
class PlannedAbsenceEditScreen extends ConsumerStatefulWidget {
  const PlannedAbsenceEditScreen({super.key, required this.absenceId});

  final String absenceId;

  @override
  ConsumerState<PlannedAbsenceEditScreen> createState() =>
      _PlannedAbsenceEditScreenState();
}

class _PlannedAbsenceEditScreenState
    extends ConsumerState<PlannedAbsenceEditScreen> {
  final _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _loadFailed = false;
  String? _baselineNote;

  @override
  void initState() {
    super.initState();
    _noteController.addListener(_onFieldChanged);
    _loadAbsence();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  bool get _isDirty =>
      _baselineNote != null && _noteController.text != _baselineNote;

  bool get _isBusy => _isSaving || _isDeleting;

  Future<void> _loadAbsence() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final absence = await ref
          .read(careContextRepositoryProvider)
          .getPlannedAbsence(widget.absenceId);
      if (mounted) {
        _noteController.text = absence.handoverNote ?? '';
      }
    } catch (_) {
      if (mounted) _loadFailed = true;
    } finally {
      if (mounted) {
        _baselineNote = _noteController.text;
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToPlan() {
    context.goNamed(
      'petCarePlannedAbsenceDetail',
      pathParameters: {'id': widget.absenceId},
    );
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

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(careContextRepositoryProvider)
          .updateHandoverNote(
            absenceId: widget.absenceId,
            handoverNote: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text,
          );
      ref.invalidate(plannedAbsenceDetailProvider(widget.absenceId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveSuccess)));
        _goToPlan();
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
          title: AppLogoTitle(title: l.careContextAwayEditTitle),
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
