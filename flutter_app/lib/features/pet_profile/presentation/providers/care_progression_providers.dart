import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/providers/api_base_url_provider.dart';
import '../../data/datasources/care_progression_remote_datasource.dart';
import '../../data/repositories/care_progression_repository_impl.dart';
import '../../domain/entities/care_establishment.dart';
import '../../domain/repositories/care_progression_repository.dart';

final careProgressionRemoteDataSourceProvider =
    Provider<CareProgressionRemoteDataSource>((ref) {
      final baseUrl = ref.watch(apiBaseUrlProvider);
      final token = ref.watch(authProvider).accessToken;
      final ds = CareProgressionRemoteDataSource(
        baseUrl: baseUrl,
        client: ref.watch(authHttpClientProvider),
      );
      ds.authToken = token;
      return ds;
    });

final careProgressionRepositoryProvider = Provider<CareProgressionRepository>(
  (ref) => CareProgressionRepositoryImpl(
    ref.watch(careProgressionRemoteDataSourceProvider),
  ),
);

final petCareEstablishmentsProvider =
    FutureProvider.family<List<CareEstablishment>, String>((ref, petId) async {
      return ref.read(careProgressionRepositoryProvider).getEstablishments(
        petId,
      );
    });
