import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/pet_care_all_pets_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_cache_freshness.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_tags/domain/entities/pet_tag.dart';
import 'package:pet_profile_app/features/pet_tags/presentation/providers/pet_tag_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _UnknownMetadataNotifier extends PetListFetchMetadataNotifier {
  @override
  PetListFetchMetadata build() =>
      const PetListFetchMetadata(freshness: PetCacheFreshness.unknown);
}

class _EmptyPetTagListNotifier extends PetTagListNotifier {
  @override
  Future<List<PetTag>> build() async => [];
}

class _LoadedPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => [
    const Pet(id: 'p1', name: 'Buddy', species: 'Dog'),
  ];
}

void main() {
  testWidgets('PetCareAllPetsScreen shows out-of-date banner when unknown', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pc/pets',
      routes: [
        GoRoute(
          path: '/pc/pets',
          builder: (context, state) => const PetCareAllPetsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          petListFetchMetadataProvider.overrideWith(
            () => _UnknownMetadataNotifier(),
          ),
          petListProvider.overrideWith(() => _LoadedPetListNotifier()),
          petTagListProvider.overrideWith(_EmptyPetTagListNotifier.new),
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

    expect(find.text('Saved data may be out of date'), findsOneWidget);
  });
}
