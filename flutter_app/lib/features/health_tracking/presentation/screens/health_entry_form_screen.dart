import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/form/app_form_breakpoints.dart';
import '../../../../core/widgets/form/app_form_discard_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../../care_taxonomy/domain/care_planning_mode.dart';
import '../../domain/entities/health_entry.dart';
import '../controllers/health_entry_form_controller.dart';
import '../controllers/health_entry_form_outcomes.dart';
import '../providers/health_providers.dart';
import '../widgets/health_entry_form/health_entry_document_handler.dart';
import '../widgets/health_entry_form/health_entry_form_actions_bar.dart';
import '../widgets/health_entry_form/health_entry_form_screen_body.dart';

/// All pet event types on the unified edit form (W18).
const kAllPetEventTypes = HealthEntryType.values;

/// Redirects legacy `/pet/:petId/health/edit/:id` and `/other/edit/:id` paths.
String? legacyPetEventEditRedirectForPath(String path) {
  final healthMatch = RegExp(
    r'^/pet/([^/]+)/health/edit/([^/]+)$',
  ).firstMatch(path);
  if (healthMatch != null) {
    return '/pet/${healthMatch.group(1)}/events/${healthMatch.group(2)}/edit';
  }
  final otherMatch = RegExp(
    r'^/pet/([^/]+)/other/edit/([^/]+)$',
  ).firstMatch(path);
  if (otherMatch != null) {
    return '/pet/${otherMatch.group(1)}/events/${otherMatch.group(2)}/edit';
  }
  return null;
}

String? redirectLegacyPetEventEditPath(GoRouterState state) =>
    legacyPetEventEditRedirectForPath(state.uri.path);

class HealthEntryFormScreen extends ConsumerStatefulWidget {
  const HealthEntryFormScreen({
    super.key,
    this.entryId,
    this.petId,
    this.initialType,
    this.allowedTypes,
    this.initialPlanningMode,
  });

  final String? entryId;
  final String? petId;
  final HealthEntryType? initialType;

  /// When set, restricts the type dropdown (e.g. pet profile health events).
  final List<HealthEntryType>? allowedTypes;

  /// Initial planning mode for add flows (`planned` default, `unplanned` for record).
  final CarePlanningMode? initialPlanningMode;

  @override
  ConsumerState<HealthEntryFormScreen> createState() =>
      _HealthEntryFormScreenState();
}

class _HealthEntryFormScreenState extends ConsumerState<HealthEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final HealthEntryFormParams _params;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _params = HealthEntryFormParams(
      entryId: widget.entryId,
      petId: widget.petId,
      initialType: widget.initialType,
      allowedTypes: widget.allowedTypes,
      initialPlanningMode: widget.initialPlanningMode,
    );
    if (widget.entryId != null) {
      Future.microtask(() async {
        try {
          final loaded = await _controller.loadEntry(widget.entryId!);
          if (loaded) {
            await _controller.loadPhotos();
          } else if (mounted) {
            _controller.captureBaseline();
          }
        } catch (e) {
          if (mounted) {
            _controller.captureBaseline();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToLoadEntry('$e'),
                ),
              ),
            );
          }
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.captureBaseline();
      });
    }
  }

  HealthEntryFormController get _controller =>
      ref.read(healthEntryFormControllerProvider(_params).notifier);

  HealthEntryDocumentHandler get _documents => HealthEntryDocumentHandler(
    ref: ref,
    context: context,
    controller: _controller,
    entryId: widget.entryId,
    isMounted: () => mounted,
  );

  Future<bool> _confirmDiscard() async {
    if (!_controller.isDirty || !mounted) return true;
    return confirmDiscardFormChanges(context);
  }

  Future<void> _handleBack() async {
    final form = ref.read(healthEntryFormControllerProvider(_params));
    if (!form.isEdit || !_controller.isDirty) {
      _navigateBack(context, form.isEdit);
      return;
    }
    if (await _confirmDiscard() && mounted) {
      _navigateBack(context, form.isEdit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final form = ref.watch(healthEntryFormControllerProvider(_params));
    final isPhone =
        AppFormBreakpoints.layoutForWidth(MediaQuery.sizeOf(context).width) ==
        AppFormLayoutSize.phone;

    return PopScope(
      canPop: !form.isEdit || !_controller.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _navigateBack(context, form.isEdit);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(
            title: form.isEdit
                ? l.editEntry
                : (form.isRecordMode ? l.recordHealthEntry : l.addHealthEntry2),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l.goBack,
            onPressed: _handleBack,
          ),
        ),
        body: form.isLoading
            ? const Center(child: CircularProgressIndicator())
            : HealthEntryFormScreenBody(
                formKey: _formKey,
                params: _params,
                documents: _documents,
                baseUrl: ref.watch(apiBaseUrlProvider),
                actionsBar: HealthEntryFormActionsBar(
                  params: _params,
                  isLoading: _isSubmitting,
                  onSave: _submit,
                  onCancel: _handleBack,
                ),
                onDelete: form.isEdit ? _confirmDelete : null,
              ),
        bottomNavigationBar: isPhone && !form.isLoading
            ? HealthEntryFormStickyActionsBar(
                params: _params,
                isLoading: _isSubmitting,
                onSave: _submit,
                onCancel: _handleBack,
              )
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    var outcome = await _controller.submit();
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (outcome is HealthEntrySubmitNeedsMarkCompleted) {
      final prompt = outcome.prompt;
      final l = AppLocalizations.of(context)!;
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.markAsCompletedTitle),
          content: Text(
            prompt.isPast ? l.markCompletedPast : l.markCompletedToday,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.keepActive),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.markCompletedAction),
            ),
          ],
        ),
      );
      if (result == null) return;
      setState(() => _isSubmitting = true);
      outcome = await _controller.submit(
        markCompleted: result,
        skipMarkCompletedCheck: true,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }

    final l = AppLocalizations.of(context)!;
    switch (outcome) {
      case HealthEntrySubmitValidationFailed(:final reason):
        if (reason == HealthEntrySubmitValidation.careFamilyRequired) {
          _controller.markCareFamilyValidationAttempted();
        }
        _formKey.currentState!.validate();
      case HealthEntrySubmitError(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$error'))));
      case HealthEntrySubmitSuccess(:final isEdit, :final petIds):
        for (final petId in petIds) {
          ref.invalidate(petHealthEntriesProvider(petId));
        }
        final count = petIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? l.entryUpdated
                  : count > 1
                  ? l.entriesCreated(count)
                  : l.entryCreated,
            ),
          ),
        );
        if (isEdit &&
            widget.entryId != null &&
            widget.petId != null &&
            widget.petId!.isNotEmpty) {
          context.go('/pet/${widget.petId}/events/${widget.entryId}');
        } else if (widget.petId != null && widget.petId!.isNotEmpty) {
          goToPetDetail(context, widget.petId!);
        } else {
          context.go('/pc/events');
        }
      case HealthEntrySubmitNeedsMarkCompleted():
        break;
    }
  }

  void _navigateBack(BuildContext context, bool isEdit) {
    if (isEdit &&
        widget.entryId != null &&
        widget.petId != null &&
        widget.petId!.isNotEmpty) {
      context.go('/pet/${widget.petId}/events/${widget.entryId}');
    } else if (widget.petId != null && widget.petId!.isNotEmpty) {
      goToPetDetail(context, widget.petId!);
    } else {
      context.go('/pc/events');
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.entryId == null) return;
    final form = ref.read(healthEntryFormControllerProvider(_params));
    final l = AppLocalizations.of(context)!;
    final isRecurring = form.frequency != HealthFrequency.once;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteEntry),
        content: Text(
          isRecurring
              ? l.deleteRecurringEntryNamedConfirm(form.name)
              : l.deleteEntryNamedConfirm(form.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(healthEntriesNotifierProvider.notifier)
          .delete(widget.entryId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.entryDeleted)),
        );
        if (widget.petId != null && widget.petId!.isNotEmpty) {
          goToPetDetail(context, widget.petId!);
        } else {
          context.go('/pc/events');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToDelete('$e')),
          ),
        );
      }
    }
  }
}
