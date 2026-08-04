import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_connection.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/organization_connections_section.dart';
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

Future<void> _pumpSection(
  WidgetTester tester, {
  required List<OrgConnection> connections,
  List<GoRoute> extraRoutes = const [],
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final l = AppLocalizations.of(context)!;
              return OrganizationConnectionsSection(
                orgId: _orgId,
                theme: theme,
                colorScheme: theme.colorScheme,
                l: l,
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/o/orgs/discover',
        builder: (context, state) =>
            const Scaffold(body: Text('discover-screen')),
      ),
      ...extraRoutes,
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        organizationRepositoryProvider.overrideWithValue(
          _ConnectionsRepo(connections),
        ),
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
  group('OrganizationConnectionsSection', () {
    testWidgets('shows connections without collapsible header', (tester) async {
      await _pumpSection(
        tester,
        connections: const [
          OrgConnection(id: 'c1', peerOrgId: 'p1', peerOrgName: 'Partner Paws'),
        ],
      );

      expect(find.byKey(const Key('org_connections_header')), findsNothing);
      expect(find.text('Partner Paws'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('does not show connect button at bottom', (tester) async {
      await _pumpSection(tester, connections: const []);

      expect(find.byKey(const Key('org_create_connection')), findsNothing);
      expect(find.text('Connect to organisation'), findsNothing);
      expect(find.text('Manage members'), findsNothing);
    });

    testWidgets('discover CTA opens discover with org browse-as context', (
      tester,
    ) async {
      await _pumpSection(tester, connections: const []);

      await tester.tap(find.byKey(const Key('org_connections_discover')));
      await tester.pumpAndSettle();

      expect(find.text('discover-screen'), findsOneWidget);
    });
  });
}
