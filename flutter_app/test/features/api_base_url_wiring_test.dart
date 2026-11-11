import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';

/// Guards that sharing remote datasources are wired through [apiBaseUrlProvider]
/// rather than a hardcoded default, so the whole app targets one consistent API
/// prefix (e.g. '/backend' on web).
void main() {
  ProviderContainer makeContainer(String baseUrl) {
    return ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue(baseUrl),
        authHttpClientProvider.overrideWithValue(http.Client()),
      ],
    );
  }

  test('sharing datasource uses apiBaseUrlProvider', () {
    final container = makeContainer('/backend');
    addTearDown(container.dispose);
    final ds = container.read(sharingDataSourceProvider);
    expect(ds.baseUrl, '/backend');
  });
}
