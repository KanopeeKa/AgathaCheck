import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../../core/widgets/form/app_form_breakpoints.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../../domain/entities/planned_absence.dart';
import '../planned_absence_date_rules.dart';
import '../providers/care_context_providers.dart';
import '../widgets/planned_absence_dates_step.dart';
import '../widgets/planned_absence_pets_step.dart';
import '../widgets/planned_absence_preview_step.dart';

/// Single-scroll create form (title, dates, pets, care preview) — not a wizard.
class PlannedAbsenceFlowScreen extends ConsumerStatefulWidget {
  const PlannedAbsenceFlowScreen({super.key});

  @override
  ConsumerState<PlannedAbsenceFlowScreen> createState() =>
      _PlannedAbsenceFlowScreenState();
}

class _PlannedAbsenceFlowScreenState
    extends ConsumerState<PlannedAbsenceFlowScreen> {
  final _titleController = TextEditingController();
  final _controller = PetListController();

  DateTime? _startsOn;
  DateTime? _endsOn;
  Set<String> _selectedPetIds = {};
  bool _hasInitializedPetSelection = false;
  bool _isSaving = false;
  String? _datesValidationMessage;
  String? _petsValidationMessage;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<Pet> _selectablePets(List<Pet> allPets) {
    return _controller
        .guardianShellPets(allPets)
        .where((pet) => !pet.passedAway)
        .toList(growable: false);
  }

  void _initializePetSelection(
    List<Pet> selectablePets, {
    String? preselectPetId,
  }) {
    if (_hasInitializedPetSelection || selectablePets.isEmpty) return;
    _hasInitializedPetSelection = true;
    if (preselectPetId != null &&
        selectablePets.any((pet) => pet.id == preselectPetId)) {
      _selectedPetIds = {preselectPetId};
    } else {
      _selectedPetIds = selectablePets.map((pet) => pet.id).toSet();
    }
  }

  String? _startsOnWire() => PlannedAbsenceDateRules.startsOnWire(_startsOn);

  String? _endsOnWire() => PlannedAbsenceDateRules.endsOnWire(_endsOn);

  bool get _hasValidDates =>
      PlannedAbsenceDateRules.isValidRange(_startsOn, _endsOn);

  bool _petsReady(AsyncValue<List<Pet>> petsAsync) => petsAsync.hasValue;

  bool _canSave(AsyncValue<List<Pet>> petsAsync) =>
      _petsReady(petsAsync) && _hasValidDates && _selectedPetIds.isNotEmpty;

  bool _validateForSave(AppLocalizations l) {
    var ok = true;
    if (!_hasValidDates) {
      if (_startsOn == null || _endsOn == null) {
        _datesValidationMessage = l.careContextAwayDatesRequired;
      } else if (_endsOn!.isBefore(_startsOn!)) {
        _datesValidationMessage = l.careContextAwayDatesInvalid;
      } else {
        _datesValidationMessage = l.careContextAwayDatesHorizon;
      }
      ok = false;
    } else {
      _datesValidationMessage = null;
    }
    if (_selectedPetIds.isEmpty) {
      _petsValidationMessage = l.careContextAwayPetsRequired;
      ok = false;
    } else {
      _petsValidationMessage = null;
    }
    return ok;
  }

  void _invalidatePreviewProviders() {
    final startsOn = _startsOnWire();
    final endsOn = _endsOnWire();
    if (startsOn == null || endsOn == null) return;
    for (final petId in _selectedPetIds) {
      ref.invalidate(
        carePeriodCoverageProvider((
          petId: petId,
          startsOn: startsOn,
          endsOn: endsOn,
          plannedAbsenceId: null,
        )),
      );
    }
  }

  Future<void> _saveAbsence(List<Pet> allPets) async {
    final l = AppLocalizations.of(context)!;
    if (!_validateForSave(l)) {
      setState(() {});
      return;
    }
    final startsOn = _startsOnWire();
    final endsOn = _endsOnWire();
    if (startsOn == null || endsOn == null) return;

    final title = _titleController.text.trim();
    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(careContextRepositoryProvider)
          .createPlannedAbsence(
            startsOn: startsOn,
            endsOn: endsOn,
            petIds: _selectedPetIds.toList(growable: false),
            title: title.isEmpty ? null : title,
          );
      ref.invalidate(plannedAbsencesListProvider);
      if (!mounted) return;
      _showOverlapWarnings(result.overlapWarnings, allPets);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveSuccess)));
      final petIds = result.absence.petIds;
      if (petIds.length == 1) {
        context.goNamed(
          'petCarePetAwayPlan',
          pathParameters: {'id': result.absence.id, 'petId': petIds.first},
        );
      } else {
        context.goNamed(
          'petCarePlannedAbsenceDetail',
          pathParameters: {'id': result.absence.id},
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveFailed)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showOverlapWarnings(
    List<PlannedAbsenceOverlapWarning> warnings,
    List<Pet> allPets,
  ) {
    if (warnings.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final namesById = {for (final pet in allPets) pet.id: pet.name};
    for (final warning in warnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.careContextAwayOverlapWarning(
              namesById[warning.petId] ?? l.petLabel,
              warning.conflictingStartsOn,
              warning.conflictingEndsOn,
            ),
          ),
        ),
      );
    }
  }

  void _handleCancel() {
    context.pop();
  }

  AwayPlanPetsLoadPhase _petsLoadPhase(AsyncValue<List<Pet>> petsAsync) {
    return petsAsync.when(
      loading: () => AwayPlanPetsLoadPhase.loading,
      error: (_, __) => AwayPlanPetsLoadPhase.error,
      data: (_) => AwayPlanPetsLoadPhase.ready,
    );
  }

  Widget _formBody(
    AppLocalizations l, {
    required AsyncValue<List<Pet>> petsAsync,
    required List<Pet> selectablePets,
    required String? startsOn,
    required String? endsOn,
    required Map<String, String> petNamesById,
    required bool includeActions,
    required VoidCallback onRetryPetsLoad,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('planned_absence_title'),
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
          validationMessage: _datesValidationMessage,
          onRangeChanged: (start, end) => setState(() {
            _startsOn = start;
            _endsOn = end;
            _datesValidationMessage = null;
            if (_hasValidDates) {
              _invalidatePreviewProviders();
            }
          }),
        ),
        const SizedBox(height: 16),
        PlannedAbsencePetsStep(
          loadPhase: _petsLoadPhase(petsAsync),
          pets: selectablePets,
          accountHasPets: (petsAsync.valueOrNull ?? const []).isNotEmpty,
          selectedPetIds: _selectedPetIds,
          validationMessage: _petsValidationMessage,
          onRetryPetsLoad: onRetryPetsLoad,
          onSelectionChanged: (next) => setState(() {
            _selectedPetIds = next;
            _petsValidationMessage = null;
            if (_hasValidDates) {
              _invalidatePreviewProviders();
            }
          }),
        ),
        if (startsOn != null && endsOn != null) ...[
          const SizedBox(height: 24),
          PlannedAbsencePreviewStep(
            startsOn: startsOn,
            endsOn: endsOn,
            petNamesById: petNamesById,
            selectedPetIds: _selectedPetIds.toList(growable: false),
            onRetry: _invalidatePreviewProviders,
          ),
        ],
        if (includeActions) ...[
          const SizedBox(height: 24),
          AppFormActionsBar(
            isLoading: _isSaving,
            isDirty: _canSave(petsAsync),
            onSave: () => _saveAbsence(selectablePets),
            onCancel: _handleCancel,
            saveLabel: l.careContextAwaySaveAction,
            cancelKey: const Key('planned_absence_cancel'),
            saveKey: const Key('planned_absence_save'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);
    final allPets = petsAsync.valueOrNull ?? const <Pet>[];
    final selectablePets = _selectablePets(allPets);
    final startsOn = _startsOnWire();
    final endsOn = _endsOnWire();
    final petNamesById = {for (final pet in selectablePets) pet.id: pet.name};

    final preselectPetId = GoRouterState.of(
      context,
    ).uri.queryParameters['petId'];

    if (petsAsync.hasValue &&
        !_hasInitializedPetSelection &&
        selectablePets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasInitializedPetSelection) return;
        setState(
          () => _initializePetSelection(
            selectablePets,
            preselectPetId: preselectPetId,
          ),
        );
      });
    }

    void retryPetsLoad() => ref.invalidate(petListProvider);

    final backPath = GoRouterState.of(context).uri.path == '/pc/away/new'
        ? '/pc/away'
        : '/pc/home';

    final isPhone =
        AppFormBreakpoints.layoutForWidth(MediaQuery.sizeOf(context).width) ==
        AppFormLayoutSize.phone;

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.careContextAwayFlowTitle,
      backPath: backPath,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = AppFormBreakpoints.layoutForWidth(
                  constraints.maxWidth,
                );
                final includeActions = layout != AppFormLayoutSize.phone;
                final form = _formBody(
                  l,
                  petsAsync: petsAsync,
                  selectablePets: selectablePets,
                  startsOn: startsOn,
                  endsOn: endsOn,
                  petNamesById: petNamesById,
                  includeActions: includeActions,
                  onRetryPetsLoad: retryPetsLoad,
                );
                if (layout == AppFormLayoutSize.phone) {
                  return SingleChildScrollView(
                    key: const Key('planned_absence_create_page'),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    child: form,
                  );
                }
                return Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
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
          ),
          if (isPhone)
            AppFormStickyActionsBar(
              stickyKey: const Key('planned_absence_sticky_actions'),
              isLoading: _isSaving,
              isDirty: _canSave(petsAsync),
              onSave: () => _saveAbsence(allPets),
              onCancel: _handleCancel,
              saveLabel: l.careContextAwaySaveAction,
              cancelKey: const Key('planned_absence_cancel'),
              saveKey: const Key('planned_absence_save'),
            ),
        ],
      ),
    );
  }
}
