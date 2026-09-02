import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_detail_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';

const _pet = Pet(id: 'pet-nav-1', name: 'Buddy', species: 'Dog');

class _AllPetsStub extends StatelessWidget {
  const _AllPetsStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('open_pet_from_all_pets'),
          onPressed: () => openPetDetail(context, _pet.id),
          child: const Text('Open Buddy'),
        ),
      ),
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _app({required GoRouter router}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      allPetsIncludingOrgProvider.overrideWith((ref) async => [_pet]),
      organizationListProvider.overrideWith(FakeOrganizationListNotifier.new),
      healthEntriesNotifierProvider.overrideWith(FakeHealthEntriesNotifier.new),
      combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
      guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
      orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
      vetListProvider.overrideWith(FakeVetListNotifier.new),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
      latestWeightProvider.overrideWith((ref, arg) => null),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

GoRouter _router(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/g/home',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Dashboard'))),
      ),
      GoRoute(
        path: '/g/pets',
        builder: (context, state) => const _AllPetsStub(),
      ),
      GoRoute(
        path: '/pet/:petId',
        builder: (context, state) =>
            PetDetailScreen(petId: state.pathParameters['petId']!),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pet detail back navigation', () {
    testWidgets('deep link without returnTo falls back to /g/home', (
      tester,
    ) async {
      final router = _router('/pet/pet-nav-1');
      await tester.pumpWidget(_app(router: router));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('experience_back_button')));
      await _settle(tester);

      expect(router.routerDelegate.currentConfiguration.uri.path, '/g/home');
    });

    testWidgets('returnTo query navigates back without stack', (tester) async {
      final router = _router(
        '/pet/pet-nav-1?returnTo=${Uri.encodeComponent('/g/pets')}',
      );
      await tester.pumpWidget(_app(router: router));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('experience_back_button')));
      await _settle(tester);

      expect(router.routerDelegate.currentConfiguration.uri.path, '/g/pets');
    });
  });
}
