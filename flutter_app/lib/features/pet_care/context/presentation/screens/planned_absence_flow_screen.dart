import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/domain/entities/app_experience.dart';
import '../../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/planned_absence.dart';
import '../planned_absence_date_rules.dart';
import '../providers/care_context_providers.dart';
import '../widgets/planned_absence_dates_step.dart';
import '../widgets/planned_absence_pets_step.dart';
import '../widgets/planned_absence_preview_step.dart';

class PlannedAbsenceFlowScreen extends ConsumerStatefulWidget {
  const PlannedAbsenceFlowScreen({super.key});

  @override
  ConsumerState<PlannedAbsenceFlowScreen> createState() =>
      _PlannedAbsenceFlowScreenState();
}

class _PlannedAbsenceFlowScreenState
    extends ConsumerState<PlannedAbsenceFlowScreen> {
  static const _stepCount = 3;

  final _pageController = PageController();
  final _controller = PetListController();

  int _step = 0;
  DateTime? _startsOn;
  DateTime? _endsOn;
  Set<String> _selectedPetIds = {};
  bool _hasInitializedPetSelection = false;
  bool _isSaving = false;
  String? _stepValidationMessage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Pet> _selectablePets(List<Pet> allPets) {
    return _controller
        .guardianShellPets(allPets)
        .where((pet) => !pet.passedAway)
        .toList(growable: false);
  }

  void _initializePetSelection(List<Pet> selectablePets) {
    if (_hasInitializedPetSelection || selectablePets.isEmpty) return;
    _hasInitializedPetSelection = true;
    _selectedPetIds = selectablePets.map((pet) => pet.id).toSet();
  }

  String? _startsOnWire() => PlannedAbsenceDateRules.startsOnWire(_startsOn);

  String? _endsOnWire() => PlannedAbsenceDateRules.endsOnWire(_endsOn);

  bool _validateCurrentStep(List<Pet> allPets) {
    final l = AppLocalizations.of(context)!;
    if (_step == 0) {
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
    } else if (_step == 1) {
      if (_selectedPetIds.isEmpty) {
        _stepValidationMessage = l.careContextAwayPetsRequired;
        return false;
      }
    }
    _stepValidationMessage = null;
    return true;
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
        )),
      );
    }
  }

  void _nextStep(List<Pet> allPets) {
    if (!_validateCurrentStep(allPets)) {
      setState(() {});
      return;
    }
    if (_step >= _stepCount - 1) return;
    setState(() {
      _step += 1;
      _stepValidationMessage = null;
    });
    if (_step == 2) {
      _invalidatePreviewProviders();
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _previousStep() {
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() {
      _step -= 1;
      _stepValidationMessage = null;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _saveAbsence(List<Pet> allPets) async {
    final l = AppLocalizations.of(context)!;
    if (!_validateCurrentStep(allPets)) {
      setState(() {});
      return;
    }
    final startsOn = _startsOnWire();
    final endsOn = _endsOnWire();
    if (startsOn == null || endsOn == null) return;

    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(careContextRepositoryProvider)
          .createPlannedAbsence(
            startsOn: startsOn,
            endsOn: endsOn,
            petIds: _selectedPetIds.toList(growable: false),
          );
      ref.invalidate(plannedAbsencesListProvider);
      if (!mounted) return;
      _showOverlapWarnings(result.overlapWarnings, allPets);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveSuccess)));
      context.pop();
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);
    final allPets = petsAsync.valueOrNull ?? const <Pet>[];
    final selectablePets = _selectablePets(allPets);
    final startsOn = _startsOnWire();
    final endsOn = _endsOnWire();
    final petNamesById = {for (final pet in selectablePets) pet.id: pet.name};

    if (!_hasInitializedPetSelection && selectablePets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasInitializedPetSelection) return;
        setState(() => _initializePetSelection(selectablePets));
      });
    }

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.careContextAwayFlowTitle,
      backPath: '/pc/home',
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / _stepCount,
            minHeight: 4,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: PlannedAbsenceDatesStep(
                    startsOn: _startsOn,
                    endsOn: _endsOn,
                    validationMessage: _step == 0
                        ? _stepValidationMessage
                        : null,
                    onRangeChanged: (start, end) => setState(() {
                      _startsOn = start;
                      _endsOn = end;
                    }),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: PlannedAbsencePetsStep(
                    pets: selectablePets,
                    selectedPetIds: _selectedPetIds,
                    validationMessage: _step == 1
                        ? _stepValidationMessage
                        : null,
                    onSelectionChanged: (next) =>
                        setState(() => _selectedPetIds = next),
                  ),
                ),
                if (startsOn != null && endsOn != null)
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: PlannedAbsencePreviewStep(
                      startsOn: startsOn,
                      endsOn: endsOn,
                      petNamesById: petNamesById,
                      selectedPetIds: _selectedPetIds.toList(growable: false),
                      onRetry: _invalidatePreviewProviders,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  TextButton(
                    key: const Key('planned_absence_back'),
                    onPressed: _isSaving ? null : _previousStep,
                    child: Text(_step == 0 ? l.cancel : l.careContextAwayBack),
                  ),
                  const Spacer(),
                  if (_step < _stepCount - 1)
                    FilledButton(
                      key: const Key('planned_absence_continue'),
                      onPressed: _isSaving ? null : () => _nextStep(allPets),
                      child: Text(l.careContextAwayContinue),
                    )
                  else ...[
                    TextButton(
                      key: const Key('planned_absence_done_without_save'),
                      onPressed: _isSaving ? null : () => context.pop(),
                      child: Text(l.careContextAwaySkipSave),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('planned_absence_save'),
                      onPressed: _isSaving ? null : () => _saveAbsence(allPets),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.careContextAwaySaveAction),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
