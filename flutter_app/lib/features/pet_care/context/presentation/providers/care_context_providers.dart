import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../../core/providers/api_base_url_provider.dart';
import '../../data/datasources/care_context_remote_datasource.dart';
import '../../data/repositories/care_context_repository_impl.dart';
import '../../domain/entities/care_period_coverage.dart';
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
