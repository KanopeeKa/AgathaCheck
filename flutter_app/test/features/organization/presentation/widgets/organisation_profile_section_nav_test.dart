import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_connection.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_profile/organisation_profile_member_sections.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

const _orgId = 'org-1';

class _ConnectionsRepo extends RecordingOrganizationRepository {
  _ConnectionsRepo(this._connections);

  final List<OrgConnection> _connections;

  @override
  Future<List<OrgConnection>> getConnections(
    String orgId,
    String token,
  ) async => _connections;
}

class _MemberOrgsNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: _orgId,
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
      memberCount: 4,
      externalCount: 2,
      petCount: 7,
    ),
  ];
}

Future<void> _pumpNav(
  WidgetTester tester, {
  required Set<String> permissions,
  RecordingOrganizationRepository? repo,
}) async {
  final connectionsRepo =
      repo ??
      _ConnectionsRepo(const [
        OrgConnection(id: 'c1', peerOrgId: 'p1', peerOrgName: 'Partner Paws'),
        OrgConnection(id: 'c2', peerOrgId: 'p2', peerOrgName: 'Other Org'),
      ]);
  final router = GoRouter(
    initialLocation: '/o/orgs/$_orgId',
    routes: [
      GoRoute(
        path: '/o/orgs/:id',
        builder: (context, state) => Scaffold(
          body: OrganisationProfileMemberSections(
            orgId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/o/orgs/:id/people',
        builder: (context, state) => Scaffold(
          body: Text(
            state.uri.queryParameters['filter'] == 'admins'
                ? 'admin contacts screen'
                : 'people screen',
          ),
        ),
      ),
      GoRoute(
        path: '/o/orgs/:id/fosters',
        builder: (context, state) =>
            const Scaffold(body: Text('fosters screen')),
      ),
      GoRoute(
        path: '/o/orgs/:id/sessions',
        builder: (context, state) =>
            const Scaffold(body: Text('sessions screen')),
      ),
      GoRoute(
        path: '/o/orgs/:id/pets',
        builder: (context, state) => const Scaffold(body: Text('pets screen')),
      ),
      GoRoute(
        path: '/o/orgs/:id/connections',
        builder: (context, state) =>
            const Scaffold(body: Text('connections screen')),
      ),
      GoRoute(
        path: '/o/orgs/:id/customisations',
        builder: (context, state) =>
            const Scaffold(body: Text('administration screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        organizationRepositoryProvider.overrideWithValue(connectionsRepo),
        organizationListProvider.overrideWith(_MemberOrgsNotifier.new),
        orgEffectivePermissionsProvider(
          _orgId,
        ).overrideWith((ref) async => permissions),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OrganisationProfileSectionNav', () {
    testWidgets('shows only admin contacts row when that view key is granted', (
      tester,
    ) async {
      await _pumpNav(tester, permissions: {'view_admin_contacts'});

      expect(
        find.byKey(const Key('org_profile_nav_admin_contacts')),
        findsOneWidget,
      );
      expect(find.text('Admin contacts'), findsOneWidget);
      expect(
        find.byKey(const Key('org_profile_nav_foster_parents')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('org_profile_nav_fostering_sessions')),
        findsNothing,
      );
      expect(find.byKey(const Key('org_profile_nav_pets')), findsNothing);
      expect(find.byKey(const Key('org_profile_nav_people')), findsOneWidget);
      expect(
        find.byKey(const Key('org_profile_nav_connections')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('org_profile_nav_administration')),
        findsNothing,
      );
    });

    testWidgets('shows fostering sessions only for view_fostering_sessions', (
      tester,
    ) async {
      await _pumpNav(tester, permissions: {'view_fostering_sessions'});

      expect(
        find.byKey(const Key('org_profile_nav_fostering_sessions')),
        findsOneWidget,
      );
      expect(find.text('Fostering sessions'), findsOneWidget);
      expect(find.byKey(const Key('org_profile_nav_pets')), findsNothing);
      expect(find.byKey(const Key('org_profile_nav_people')), findsOneWidget);
    });

    testWidgets('shows people row without permission gate', (tester) async {
      await _pumpNav(tester, permissions: {});

      expect(find.byKey(const Key('org_profile_nav_people')), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
    });

    testWidgets('shows pets row with pet count for view_org_pets', (
      tester,
    ) async {
      await _pumpNav(tester, permissions: {'view_org_pets'});

      expect(find.byKey(const Key('org_profile_nav_pets')), findsOneWidget);
      expect(find.byKey(const Key('org_profile_nav_people')), findsOneWidget);
      expect(find.text('Pets'), findsOneWidget);
      expect(find.text('7 pets'), findsOneWidget);
    });

    testWidgets(
      'shows connections row with count when view_connections granted',
      (tester) async {
        await _pumpNav(tester, permissions: {'view_connections'});

        expect(
          find.byKey(const Key('org_profile_nav_connections')),
          findsOneWidget,
        );
        expect(find.text('Connected organisations'), findsOneWidget);
        expect(find.text('2 connections'), findsOneWidget);
        expect(find.text('Manage members'), findsNothing);
      },
    );

    testWidgets('shows administration row only for manage_permissions', (
      tester,
    ) async {
      await _pumpNav(tester, permissions: {'manage_permissions'});

      expect(
        find.byKey(const Key('org_profile_nav_administration')),
        findsOneWidget,
      );
      expect(find.text('Organisation Administration'), findsOneWidget);
    });

    testWidgets('shows all member nav rows when all view keys are granted', (
      tester,
    ) async {
      await _pumpNav(
        tester,
        permissions: {
          'view_admin_contacts',
          'view_org_internal',
          'view_fostering_sessions',
          'view_org_pets',
          'view_connections',
          'manage_permissions',
        },
      );

      expect(
        find.byKey(const Key('org_profile_nav_admin_contacts')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('org_profile_nav_foster_parents')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('org_profile_nav_fostering_sessions')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('org_profile_nav_pets')), findsOneWidget);
      expect(find.byKey(const Key('org_profile_nav_people')), findsOneWidget);
      expect(
        find.byKey(const Key('org_profile_nav_connections')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('org_profile_nav_administration')),
        findsOneWidget,
      );
      expect(find.text('Manage members'), findsNothing);
      expect(find.text('Manage fosters'), findsNothing);
    });

    testWidgets('connections row navigates to connections route', (
      tester,
    ) async {
      await _pumpNav(tester, permissions: {'view_connections'});

      await tester.tap(find.byKey(const Key('org_profile_nav_connections')));
      await tester.pumpAndSettle();

      expect(find.text('connections screen'), findsOneWidget);
    });

    testWidgets('pets row navigates to pets route', (tester) async {
      await _pumpNav(tester, permissions: {'view_org_pets'});

      await tester.tap(find.byKey(const Key('org_profile_nav_pets')));
      await tester.pumpAndSettle();

      expect(find.text('pets screen'), findsOneWidget);
    });

    testWidgets('people row navigates to people route', (tester) async {
      await _pumpNav(tester, permissions: {});

      await tester.tap(find.byKey(const Key('org_profile_nav_people')));
      await tester.pumpAndSettle();

      expect(find.text('people screen'), findsOneWidget);
    });

    testWidgets('admin contacts row navigates to filtered people route', (
      tester,
    ) async {
      await _pumpNav(tester, permissions: {'view_admin_contacts'});

      await tester.tap(find.byKey(const Key('org_profile_nav_admin_contacts')));
      await tester.pumpAndSettle();

      expect(find.text('admin contacts screen'), findsOneWidget);
    });

    testWidgets('administration row navigates to customisations route', (
      tester,
    ) async {
      await _pumpNav(tester, permissions: {'manage_permissions'});

      await tester.tap(find.byKey(const Key('org_profile_nav_administration')));
      await tester.pumpAndSettle();

      expect(find.text('administration screen'), findsOneWidget);
    });
  });
}
