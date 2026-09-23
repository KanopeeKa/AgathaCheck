import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/domain/entities/app_experience.dart';
import '../../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/care_context_providers.dart';
import '../controllers/away_plan_handover_controller.dart';
import '../widgets/away_plan_carers_section.dart';
import '../widgets/away_plan_details_section.dart';
import '../widgets/away_plan_handover_note_section.dart';
import '../widgets/away_plan_header_section.dart';
import '../widgets/away_plan_pet_care_section.dart';

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
        screenTitle: l.careContextAwayPlanTitle,
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
            final orderedPetIds = [...absence.petIds]..sort();
            void retryPetCoverage() {
              for (final petId in orderedPetIds) {
                ref.invalidate(
                  carePeriodCoverageProvider((
                    petId: petId,
                    startsOn: absence.startsOn,
                    endsOn: absence.endsOn,
                  )),
                );
              }
            }

            Future<void> downloadHandover() =>
                AwayPlanHandoverController(ref).downloadHandover(
                  context: context,
                  absence: absence,
                  readiness: readiness,
                  petNamesById: petNamesById,
                );

            return shell(
              actions: [
                IconButton(
                  key: const Key('away_plan_edit'),
                  tooltip: l.careContextAwayEditTooltip,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: absence.isCancelled
                      ? null
                      : () => context.pushNamed(
                          'petCarePlannedAbsenceEdit',
                          pathParameters: {'id': absenceId},
                        ),
                ),
                IconButton(
                  key: const Key('away_plan_download_handover'),
                  tooltip: l.downloadReport,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: absence.isCancelled ? null : downloadHandover,
                ),
              ],
              child: ListView(
                key: const Key('away_plan_page'),
                padding: const EdgeInsets.all(16),
                children: [
                  AwayPlanHeaderSection(absence: absence, readiness: readiness),
                  const SizedBox(height: 24),
                  AwayPlanCarersSection(
                    absence: absence,
                    petNamesById: petNamesById,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.careContextAwayPlanCareDuringTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...orderedPetIds.map(
                    (petId) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AwayPlanPetCareSection(
                        petId: petId,
                        petName: petNamesById[petId] ?? '',
                        startsOn: absence.startsOn,
                        endsOn: absence.endsOn,
                        onRetry: retryPetCoverage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AwayPlanHandoverNoteSection(absence: absence),
                  const SizedBox(height: 24),
                  AwayPlanDetailsSection(
                    absence: absence,
                    petNamesById: petNamesById,
                  ),
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
