import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../../core/providers/api_base_url_provider.dart';
import '../../data/datasources/care_context_remote_datasource.dart';
import '../../data/repositories/care_context_repository_impl.dart';
import '../away_planning_dashboard_tile_state.dart';
import '../../domain/entities/absence_care_plan.dart';
import '../../domain/entities/away_plan_readiness.dart';
import '../../domain/entities/care_period_coverage.dart';
import '../../domain/entities/carer_candidate.dart';
import '../../domain/entities/planned_absence.dart';
import '../../domain/repositories/care_context_repository.dart';

final careContextRemoteDataSourceProvider =
    Provider<CareContextRemoteDataSource>((ref) {
      final baseUrl = ref.watch(apiBaseUrlProvider);
      final token = ref.watch(authProvider).accessToken;
      final ds = CareContextRemoteDataSource(baseUrl: baseUrl);
      ds.authToken = token;
      return ds;
    });

final careContextRepositoryProvider = Provider<CareContextRepository>(
  (ref) =>
      CareContextRepositoryImpl(ref.watch(careContextRemoteDataSourceProvider)),
);

typedef CarePeriodPreviewKey = ({String petId, String startsOn, String endsOn});

final carePeriodCoverageProvider =
    FutureProvider.family<CarePeriodCoverageResult, CarePeriodPreviewKey>((
      ref,
      key,
    ) async {
      return ref
          .read(careContextRepositoryProvider)
          .getCarePeriodCoverage(
            petId: key.petId,
            startsOn: key.startsOn,
            endsOn: key.endsOn,
          );
    });

final plannedAbsencesListProvider = FutureProvider<List<PlannedAbsence>>((
  ref,
) async {
  return ref.read(careContextRepositoryProvider).listPlannedAbsences();
});

final plannedAbsenceDetailProvider =
    FutureProvider.family<PlannedAbsence, String>((ref, absenceId) async {
      return ref
          .read(careContextRepositoryProvider)
          .getPlannedAbsence(absenceId);
    });

final awayPlanReadinessProvider =
    FutureProvider.family<AwayPlanReadiness, String>((ref, absenceId) async {
      return ref
          .read(careContextRepositoryProvider)
          .getAwayPlanReadiness(absenceId);
    });

final absenceCarePlanProvider =
    FutureProvider.family<AbsenceCarePlan, String>((ref, absenceId) async {
      return ref
          .read(careContextRepositoryProvider)
          .getAbsenceCarePlan(absenceId);
    });

class DismissedPlannerSuggestionsNotifier extends StateNotifier<Set<String>> {
  DismissedPlannerSuggestionsNotifier() : super({});

  void dismiss(String key) {
    state = {...state, key};
  }
}

final dismissedPlannerSuggestionsProvider = StateNotifierProvider.family<
    DismissedPlannerSuggestionsNotifier,
    Set<String>,
    String>((ref, absenceId) {
  return DismissedPlannerSuggestionsNotifier();
});

final carerCandidatesProvider = FutureProvider.autoDispose
    .family<List<CarerCandidate>, String>((ref, petId) async {
      return ref.read(careContextRepositoryProvider).getCarerCandidates(petId);
    });

final awayPlanningDashboardTileProvider =
    FutureProvider<AwayPlanningDashboardTileState>((ref) async {
      try {
        final absences = await ref
            .read(careContextRepositoryProvider)
            .listPlannedAbsences(scope: 'upcoming');
        if (absences.isEmpty) return AwayPlanningDashboardTileState.prompt;
        final upcoming = absences.first;
        try {
          final readiness = await ref
              .read(careContextRepositoryProvider)
              .getAwayPlanReadiness(upcoming.id);
          return AwayPlanningDashboardTileState.stateful(
            absence: upcoming,
            tileCopy: readiness.tileCopy,
          );
        } catch (_) {
          return AwayPlanningDashboardTileState.prompt;
        }
      } catch (_) {
        return AwayPlanningDashboardTileState.prompt;
      }
    });
