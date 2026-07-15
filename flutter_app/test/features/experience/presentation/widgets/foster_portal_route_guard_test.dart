import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/foster_portal_route_guard.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';

class _FosterOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'o1',
      name: 'Shelter',
      type: OrganizationType.charity,
      role: 'foster',
    ),
  ];
}

class _AdminOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'o1',
      name: 'Shelter',
      type: OrganizationType.charity,
      role: 'admin',
    ),
  ];
}

void main() {
  testWidgets('redirects foster portal user away from blocked route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/o/invite',
      routes: [
        GoRoute(
          path: '/o/home',
          builder: (context, state) =>
              const Scaffold(body: Text('org home')),
        ),
        GoRoute(
          path: '/o/invite',
          builder: (context, state) => const FosterPortalRouteGuard(
            fallbackPath: '/o/home',
            child: Scaffold(body: Text('invite screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizationListProvider.overrideWith(_FosterOrgListNotifier.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('invite screen'), findsNothing);
    expect(find.text('org home'), findsOneWidget);
  });

  testWidgets('allows org admin through blocked route', (tester) async {
    final router = GoRouter(
      initialLocation: '/o/invite',
      routes: [
        GoRoute(
          path: '/o/home',
          builder: (context, state) =>
              const Scaffold(body: Text('org home')),
        ),
        GoRoute(
          path: '/o/invite',
          builder: (context, state) => const FosterPortalRouteGuard(
            fallbackPath: '/o/home',
            child: Scaffold(body: Text('invite screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizationListProvider.overrideWith(_AdminOrgListNotifier.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('invite screen'), findsOneWidget);
    expect(find.text('org home'), findsNothing);
  });
}
