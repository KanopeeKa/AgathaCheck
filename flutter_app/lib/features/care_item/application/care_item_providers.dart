import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/providers/api_base_url_provider.dart';
import '../data/care_item_remote_datasource.dart';
import 'care_completion_service.dart';
import 'care_items_controller.dart';

/// The authenticated HTTP client for care routes. Overridden at composition
/// (`lib/main.dart`) with the app's auth client so this feature imports no
/// other feature.
final careItemHttpClientProvider = Provider<http.Client>((ref) {
  throw UnimplementedError(
    'careItemHttpClientProvider must be overridden with the authenticated client',
  );
});

final careItemRemoteDataSourceProvider = Provider<CareItemRemoteDataSource>((
  ref,
) {
  return CareItemRemoteDataSource(
    client: ref.watch(careItemHttpClientProvider),
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
});

final careCompletionServiceProvider = Provider<CareCompletionService>((ref) {
  return CareCompletionService(ref.watch(careItemRemoteDataSourceProvider));
});

/// Care items of one pet, or of every pet the person cares for (`null`).
final careItemsControllerProvider =
    StateNotifierProvider.family<CareItemsController, CareItemsState, String?>((
      ref,
      petId,
    ) {
      return CareItemsController(
        ref.watch(careCompletionServiceProvider),
        petId: petId,
      );
    });
