import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/auth/auth.dart';
import '../../../../core/providers/api_base_url_provider.dart';
import '../../progression/data/datasources/care_progression_moments_remote_datasource.dart';
import '../../progression/data/repositories/care_progression_moments_repository_impl.dart';
import '../../progression/domain/entities/care_pending_moment.dart';
import '../../progression/domain/repositories/care_progression_moments_repository.dart';

final careProgressionMomentsRemoteDataSourceProvider =
    Provider<CareProgressionMomentsRemoteDataSource>((ref) {
      final baseUrl = ref.watch(apiBaseUrlProvider);
      final token = ref.watch(authProvider).accessToken;
      final ds = CareProgressionMomentsRemoteDataSource(
        baseUrl: baseUrl,
        client: ref.watch(authHttpClientProvider),
      );
      ds.authToken = token;
      return ds;
    });

final careProgressionMomentsRepositoryProvider =
    Provider<CareProgressionMomentsRepository>(
      (ref) => CareProgressionMomentsRepositoryImpl(
        ref.watch(careProgressionMomentsRemoteDataSourceProvider),
      ),
    );

final petPendingCareMomentsProvider =
    FutureProvider.family<CarePendingMomentsResponse, String>((
      ref,
      petId,
    ) async {
      return ref
          .read(careProgressionMomentsRepositoryProvider)
          .getPendingMoments(petId);
    });
