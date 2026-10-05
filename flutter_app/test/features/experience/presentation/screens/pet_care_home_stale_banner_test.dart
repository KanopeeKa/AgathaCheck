import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/experience_home_screens.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_cache_freshness.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _StaleMetadataNotifier extends PetListFetchMetadataNotifier {
  @override
  PetListFetchMetadata build() =>
      const PetListFetchMetadata(freshness: PetCacheFreshness.stale);
}

class _LoadedPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => [
    const Pet(id: 'p1', name: 'Buddy', species: 'Dog'),
  ];
}

void main() {
  testWidgets('PetCareHomeScreen shows cache banner when metadata is stale', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pc/home',
      routes: [
        GoRoute(
          path: '/pc/home',
          builder: (context, state) => const PetCareHomeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          petListFetchMetadataProvider.overrideWith(
            () => _StaleMetadataNotifier(),
          ),
          petListProvider.overrideWith(() => _LoadedPetListNotifier()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Offline'), findsOneWidget);
  });
}
