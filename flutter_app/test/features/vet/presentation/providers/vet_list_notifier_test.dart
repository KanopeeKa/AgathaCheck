import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';

import '../../../../helpers/fakes.dart';

class MutableAuthNotifier extends AuthNotifier {
  MutableAuthNotifier()
    : super(FakeAuthService(), PrefsTokenStore(FakePrefs())) {
    state = const AuthState();
  }

  void setLoggedIn() {
    state = loggedInAuthState;
  }
}

void main() {
  test(
    'VetListNotifier returns empty list until access token is available',
    () async {
      final auth = MutableAuthNotifier();
      final client = MockClient((request) async {
        return http.Response(
          json.encode([
            {'id': 'vet-1', 'name': 'Dr. Smith', 'address': 'Springfield'},
          ]),
          200,
        );
      });

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          authHttpClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(vetListProvider.future);
      expect(initial, isEmpty);

      auth.setLoggedIn();
      await container.read(vetListProvider.future);

      final loaded = container.read(vetListProvider).valueOrNull;
      expect(loaded, hasLength(1));
      expect(loaded!.single.name, 'Dr. Smith');
    },
  );
}
