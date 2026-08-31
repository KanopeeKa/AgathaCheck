import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fostering_session_repository.dart';
import '../../../organization/presentation/providers/org_provider_deps.dart';

final fosteringSessionRepositoryProvider = Provider<FosteringSessionRepository>(
  (ref) => FosteringSessionRepository.fromDataSource(
    ref.watch(orgRemoteDataSourceProvider),
  ),
);
