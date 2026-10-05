import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/presentation/screens/legacy_vet_contact_redirect_screen.dart';

void main() {
  testWidgets('resolved legacy vet id navigates to People contact detail', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pc/vets/vet-legacy-1',
      routes: [
        GoRoute(
          path: '/pc/vets/:id',
          builder: (context, state) => LegacyVetContactRedirectScreen(
            vetId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/pc/people/:id',
          builder: (context, state) =>
              Scaffold(body: Text('contact ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legacyVetContactIdProvider.overrideWith((ref, vetId) async {
            expect(vetId, 'vet-legacy-1');
            return 'contact-42';
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('contact contact-42'), findsOneWidget);
  });

  testWidgets('unresolved legacy vet id navigates to professionals filter', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pc/vets/missing-vet',
      routes: [
        GoRoute(
          path: '/pc/vets/:id',
          builder: (context, state) => LegacyVetContactRedirectScreen(
            vetId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/pc/people',
          builder: (context, state) => Scaffold(
            body: Text('filter ${state.uri.queryParameters['filter']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legacyVetContactIdProvider.overrideWith((ref, vetId) async => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('filter professionals'), findsOneWidget);
  });
}
