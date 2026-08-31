import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../organization/presentation/providers/foster_placements_providers.dart';
import '../../../organization/presentation/providers/org_provider_deps.dart';
import '../../data/fostering_session_repository.dart';

final fosterFosteringSessionRepositoryProvider =
    Provider<FosteringSessionRepository>((ref) {
      return FosteringSessionRepository.fromFosterDataSource(
        ref.watch(fosterPlacementsDataSourceProvider),
      );
    });

final shelterFosteringSessionRepositoryProvider =
    Provider<FosteringSessionRepository>((ref) {
      return FosteringSessionRepository.fromDataSource(
        ref.watch(orgRemoteDataSourceProvider),
      );
    });
