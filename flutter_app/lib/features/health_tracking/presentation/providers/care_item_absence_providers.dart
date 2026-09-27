import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../data/datasources/health_absence_context_remote.dart';
import '../../data/models/health_entry_absence_context_model.dart';

final healthAbsenceContextRemoteProvider = Provider<HealthAbsenceContextRemote>((
  ref,
) {
  final remote = HealthAbsenceContextRemote(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(authHttpClientProvider),
  );
  remote.authToken = ref.watch(authProvider).accessToken;
  return remote;
});

final careItemAbsenceContextProvider = FutureProvider.family<
    HealthEntryAbsenceContext,
    String
>((ref, entryId) async {
  final remote = ref.watch(healthAbsenceContextRemoteProvider);
  return remote.fetchAbsenceContext(entryId);
});
