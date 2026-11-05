import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../controllers/away_plan_handover_controller.dart';
import '../planned_absence_display.dart';
import '../providers/care_context_providers.dart';
import '../widgets/absence_pet_pill.dart';
import '../widgets/away_plan_header_section.dart';
import '../absence_pet_membership_flow.dart';
import '../planned_absence_date_rules.dart';
import '../widgets/away_plan_summary_card.dart';

/// Absence (trip) screen at `/pc/away/:id` — summary, status, pet pills.
class PlannedAbsencePlanScreen extends ConsumerWidget {
  const PlannedAbsencePlanScreen({super.key, required this.absenceId});

  final String absenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final absenceAsync = ref.watch(plannedAbsenceDetailProvider(absenceId));
    final readinessAsync = ref.watch(awayPlanReadinessProvider(absenceId));
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);

    Widget shell({required Widget child, List<Widget> actions = const []}) {
      return ExperienceShellScaffold(
        experience: AppExperience.petCare,
        currentLocation: GoRouterState.of(context).uri.path,
        screenTitle: absenceAsync.maybeWhen(
          data: (absence) =>
              PlannedAbsenceDisplay.absenceScreenTitle(l, absence),
          orElse: () => l.careContextAbsenceDefaultTitle,
        ),
        backPath: '/pc/away',
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
          onRetry: () {
            ref.invalidate(plannedAbsenceDetailProvider(absenceId));
            ref.invalidate(awayPlanReadinessProvider(absenceId));
          },
        ),
      ),
      data: (absence) => readinessAsync.when(
        loading: () =>
            shell(child: const Center(child: CircularProgressIndicator())),
        error: (_, __) => shell(
          child: _ErrorBody(
            message: l.careContextAwayPlanLoadError,
            onRetry: () {
              ref.invalidate(plannedAbsenceDetailProvider(absenceId));
              ref.invalidate(awayPlanReadinessProvider(absenceId));
            },
          ),
        ),
        data: (readiness) => petsAsync.when(
          loading: () =>
              shell(child: const Center(child: CircularProgressIndicator())),
          error: (error, _) =>
              shell(child: Center(child: Text(l.errorWithMessage('$error')))),
          data: (pets) {
            final petNamesById = {for (final pet in pets) pet.id: pet.name};
            final orderedPetIds = [...absence.petIds]
              ..sort(
                (a, b) =>
                    (petNamesById[a] ?? a).compareTo(petNamesById[b] ?? b),
              );

            Future<void> downloadHandover() =>
                AwayPlanHandoverController(ref).downloadHandover(
                  context: context,
                  absence: absence,
                  readiness: readiness,
                  petNamesById: petNamesById,
                );

            final canEditTrip =
                absence.canEditTrip ?? absence.isOwnAbsence ?? false;
            final todayIso = PlannedAbsenceDateRules.startsOnWire(
              PlannedAbsenceDateRules.todayCalendar(),
            );
            final isPast =
                todayIso != null && absence.endsOn.compareTo(todayIso) < 0;
            final showAddPet = canEditTrip && !absence.isCancelled && !isPast;

            return shell(
              actions: [
                IconButton(
                  key: const Key('away_plan_download_handover'),
                  tooltip: l.downloadReport,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: absence.isCancelled ? null : downloadHandover,
                ),
              ],
              child: ListView(
                key: const Key('absence_screen_page'),
                padding: const EdgeInsets.all(16),
                children: [
                  AwayPlanSummaryCard(
                    absence: absence,
                    onEdit: absence.isCancelled || !canEditTrip
                        ? null
                        : () => context.pushNamed(
                            'petCarePlannedAbsenceEdit',
                            pathParameters: {'id': absenceId},
                          ),
                  ),
                  AwayPlanHeaderSection(absence: absence, readiness: readiness),
                  const SizedBox(height: 24),
                  Text(
                    l.careContextAbsencePetsSectionTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (final petId in orderedPetIds) ...[
                    AbsencePetPill(
                      absenceId: absenceId,
                      petId: petId,
                      petName: petNamesById[petId] ?? '',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (showAddPet) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const Key('absence_add_pet'),
                      onPressed: () => AbsencePetMembershipFlow.showAddPetSheet(
                        context: context,
                        ref: ref,
                        absence: absence,
                        allPets: pets,
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(l.careContextAddPetToAbsence),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
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
