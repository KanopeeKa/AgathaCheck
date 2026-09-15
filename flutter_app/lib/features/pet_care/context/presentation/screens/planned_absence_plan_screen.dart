import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/domain/entities/app_experience.dart';
import '../../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/care_context_providers.dart';
import '../widgets/away_plan_carers_section.dart';
import '../widgets/away_plan_details_section.dart';
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

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.careContextAwayPlanTitle,
      backPath: '/pc/away',
      child: absenceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorBody(
          message: l.careContextAwayPlanLoadError,
          onRetry: () {
            ref.invalidate(plannedAbsenceDetailProvider(absenceId));
            ref.invalidate(awayPlanReadinessProvider(absenceId));
          },
        ),
        data: (absence) => readinessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorBody(
            message: l.careContextAwayPlanLoadError,
            onRetry: () {
              ref.invalidate(plannedAbsenceDetailProvider(absenceId));
              ref.invalidate(awayPlanReadinessProvider(absenceId));
            },
          ),
          data: (readiness) => petsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text(l.errorWithMessage('$error'))),
            data: (pets) {
              final petNamesById = {for (final pet in pets) pet.id: pet.name};
              final orderedPetIds = [...absence.petIds]..sort();
              void retryPetCoverage() {
                for (final petId in orderedPetIds) {
                  ref.invalidate(carePeriodCoverageProvider((
                    petId: petId,
                    startsOn: absence.startsOn,
                    endsOn: absence.endsOn,
                  )));
                }
              }

              return ListView(
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
                  AwayPlanDetailsSection(
                    absence: absence,
                    petNamesById: petNamesById,
                  ),
                ],
              );
            },
          ),
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
