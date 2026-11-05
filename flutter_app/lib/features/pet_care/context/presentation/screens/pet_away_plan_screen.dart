import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../providers/care_context_providers.dart';
import '../widgets/away_plan_pet_care_section.dart';
import '../widgets/away_plan_pet_carer_panel.dart';
import '../widgets/away_plan_pet_notes_section.dart';
import '../absence_pet_membership_flow.dart';
import '../widgets/away_plan_trip_read_only_header.dart';
import '../../../../../core/widgets/screen_overflow_actions.dart';

class PetAwayPlanScreen extends ConsumerWidget {
  const PetAwayPlanScreen({
    super.key,
    required this.absenceId,
    required this.petId,
  });

  final String absenceId;
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final absenceAsync = ref.watch(plannedAbsenceDetailProvider(absenceId));
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final routerState = GoRouterState.of(context);
    final returnTo = shellReturnToFromState(routerState);

    Widget shell({required Widget child, List<Widget> actions = const []}) {
      return ExperienceShellScaffold(
        experience: AppExperience.petCare,
        currentLocation: routerState.uri.path,
        screenTitle: petsAsync.maybeWhen(
          data: (pets) {
            final name = pets
                .where((p) => p.id == petId)
                .map((p) => p.name)
                .firstOrNull;
            if (name != null && name.isNotEmpty) {
              return l.careContextPetAwayPlanTitle(name);
            }
            return l.careContextAwayPlanTitle;
          },
          orElse: () => l.careContextAwayPlanTitle,
        ),
        backPath: awayPlanDetailLocation(absenceId, returnTo: returnTo),
        contextualActions: actions,
        child: child,
      );
    }

    return absenceAsync.when(
      loading: () =>
          shell(child: const Center(child: CircularProgressIndicator())),
      error: (_, __) => shell(
        child: _ErrorBody(
          message: l.careContextAwayPlanLoadError,
          onRetry: () =>
              ref.invalidate(plannedAbsenceDetailProvider(absenceId)),
        ),
      ),
      data: (absence) {
        if (!absence.petIds.contains(petId)) {
          return shell(
            child: _ErrorBody(
              message: l.careContextAwayPlanLoadError,
              onRetry: () =>
                  ref.invalidate(plannedAbsenceDetailProvider(absenceId)),
            ),
          );
        }
        return petsAsync.when(
          loading: () =>
              shell(child: const Center(child: CircularProgressIndicator())),
          error: (error, _) =>
              shell(child: Center(child: Text(l.errorWithMessage('$error')))),
          data: (pets) {
            final petNamesById = {for (final pet in pets) pet.id: pet.name};
            final petName = petNamesById[petId] ?? '';
            final pet = pets.where((p) => p.id == petId).firstOrNull;
            final carer = absence.petCarers.firstWhere(
              (row) => row.petId == petId,
              orElse: () => PlannedAbsencePetCarer(petId: petId),
            );
            final canEditTrip =
                absence.canEditTrip ?? absence.isOwnAbsence ?? false;
            final canEdit = !absence.isCancelled;
            final carerPanel = AwayPlanPetCarerPanel(
              absence: absence,
              petId: petId,
              petName: petName,
              petNamesById: petNamesById,
            );

            void retryPetCoverage() {
              ref.invalidate(
                carePeriodCoverageProvider((
                  petId: petId,
                  startsOn: absence.startsOn,
                  endsOn: absence.endsOn,
                  plannedAbsenceId: absenceId,
                )),
              );
            }

            Future<void> downloadPetPlan() =>
                carerPanel.downloadPetHandover(context, ref);

            final tripNote = absence.handoverNote?.trim();

            final overflowActions = <ScreenOverflowAction>[
              if (canEditTrip && !absence.isCancelled)
                ScreenOverflowAction(
                  key: Key('remove_pet_from_absence_$petId'),
                  menuItemKey: Key('remove_pet_from_absence_menu_$petId'),
                  semanticsIdentifier: 'remove_pet_from_absence_$petId',
                  label: l.careContextRemovePetFromAbsence(petName),
                  icon: Icons.person_remove_outlined,
                  onPressed: () => AbsencePetMembershipFlow.confirmAndRemovePet(
                    context: context,
                    ref: ref,
                    absence: absence,
                    petId: petId,
                    petName: petName,
                  ),
                ),
            ];

            return shell(
              actions: [
                IconButton(
                  key: Key('away_plan_download_pet_$petId'),
                  tooltip: l.awayPlanningDownloadPetPlan(petName),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: canEdit ? downloadPetPlan : null,
                ),
                if (overflowActions.isNotEmpty)
                  ScreenOverflowActions(
                    menuKey: Key('pet_away_plan_overflow_$petId'),
                    menuSemanticsIdentifier: 'pet_away_plan_overflow_$petId',
                    tooltip: l.moreActions,
                    actions: overflowActions,
                  ),
              ],
              child: ListView(
                key: Key('pet_away_plan_page_$petId'),
                padding: const EdgeInsets.all(16),
                children: [
                  AwayPlanTripReadOnlyHeader(absence: absence),
                  const SizedBox(height: 16),
                  Semantics(
                    identifier: 'away_plan_pet_header_$petId',
                    button: true,
                    label: l.petDetailsFor(petName),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => openPetDetail(context, petId),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CareEventRowPetAvatar(pet: pet, petName: petName),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  petName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  carerPanel,
                  const SizedBox(height: 24),
                  AwayPlanPetNotesSection(
                    absenceId: absenceId,
                    petId: petId,
                    petName: petName,
                    currentCarer: carer,
                    canEdit: canEdit,
                  ),
                  if (tripNote != null && tripNote.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      l.careContextTripNotesForWholeTrip,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(tripNote),
                  ],
                  const SizedBox(height: 24),
                  AwayPlanPetCareSection(
                    absenceId: absenceId,
                    petId: petId,
                    petName: petName,
                    startsOn: absence.startsOn,
                    endsOn: absence.endsOn,
                    onRetry: retryPetCoverage,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l.retry)),
          ],
        ),
      ),
    );
  }
}
