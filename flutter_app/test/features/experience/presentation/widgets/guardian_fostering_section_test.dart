import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_fostering_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildSection(GoRouter router) {
    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('only shows Guardian-visible foster relationship details', (
    tester,
  ) async {
    const pets = [
      Pet(
        id: 'foster-1',
        name: 'Miso',
        species: 'Cat',
        isFoster: true,
        organizationId: 'org-harbour',
        organizationName: 'Harbour Shelter',
        fosterPlacementStatus: 'active',
      ),
      Pet(id: 'owned-1', name: 'Biscuit', species: 'Dog'),
    ];
    final router = GoRouter(
      initialLocation: '/pc/home',
      routes: [
        GoRoute(
          path: '/pc/home',
          builder: (context, state) =>
              Scaffold(body: GuardianFosteringSection(pets: pets)),
        ),
      ],
    );

    await tester.pumpWidget(buildSection(router));
    await tester.pumpAndSettle();

    expect(find.text('Miso'), findsOneWidget);
    expect(find.text('Harbour Shelter'), findsNWidgets(2));
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Biscuit'), findsNothing);
  });

  testWidgets(
    'uses a truthful empty state when no foster relationship exists',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/pc/home',
        routes: [
          GoRoute(
            path: '/pc/home',
            builder: (context, state) => const Scaffold(
              body: GuardianFosteringSection(
                pets: [Pet(id: 'owned-1', name: 'Biscuit', species: 'Dog')],
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildSection(router));
      await tester.pumpAndSettle();

      expect(find.text('No fostering sessions right now'), findsOneWidget);
      expect(
        find.byKey(const Key('guardian_dashboard_empty_fostering_action')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('guardian_dashboard_empty_shelters_action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('guardian_dashboard_empty_fostering')),
        findsOneWidget,
      );
      expect(
        find.byType(Image),
        findsOneWidget,
        reason: 'the fostering illustration belongs to shelter connection',
      );
    },
  );

  testWidgets('tapping shelter row opens organisation profile with returnTo', (
    tester,
  ) async {
    late String currentLocation;
    final router = GoRouter(
      initialLocation: '/pc/home',
      routes: [
        GoRoute(
          path: '/pc/home',
          builder: (context, state) {
            currentLocation = state.uri.toString();
            return Scaffold(
              body: GuardianFosteringSection(
                pets: const [
                  Pet(
                    id: 'foster-1',
                    name: 'Miso',
                    species: 'Cat',
                    isFoster: true,
                    organizationId: 'org-harbour',
                    organizationName: 'Harbour Shelter',
                    fosterPlacementStatus: 'active',
                  ),
                ],
              ),
            );
          },
        ),
        GoRoute(
          path: '/o/orgs/:id',
          builder: (context, state) => Scaffold(
            body: Text(
              'profile:${state.pathParameters['id']}:${state.uri.query}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(buildSection(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Harbour Shelter').last);
    await tester.pumpAndSettle();

    expect(currentLocation, '/pc/home');
    expect(
      find.text('profile:org-harbour:returnTo=%2Fpc%2Fhome'),
      findsOneWidget,
    );
  });
}
