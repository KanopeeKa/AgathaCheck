import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/discoverable_organization.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_discovery_provider.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organization_discover_screen.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_discover_entry_context.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_screen_theme.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

const _dashboardOrg = Organization(
  id: 'org-home',
  name: 'Home Shelter',
  type: OrganizationType.charity,
);

class _OrgListNotifier extends OrganizationListNotifier {
  final List<Organization> orgs;

  _OrgListNotifier(this.orgs);

  @override
  Future<List<Organization>> build() async => orgs;
}

class _EmptyDiscoveryNotifier extends OrgDiscoveryListNotifier {
  @override
  Future<List<DiscoverableOrganization>> build() async => [];
}

List<Override> _discoverScreenOverrides({
  List<Organization> orgs = const [],
  bool withAuth = false,
}) {
  final overrides = <Override>[
    orgDiscoveryListProvider.overrideWith(_EmptyDiscoveryNotifier.new),
  ];
  if (orgs.isNotEmpty) {
    overrides.add(
      organizationListProvider.overrideWith(() => _OrgListNotifier(orgs)),
    );
  }
  if (withAuth) {
    overrides.add(authProvider.overrideWith((ref) => FakeAuthNotifier()));
  }
  return overrides;
}

void main() {
  testWidgets(
    'browse-as banner shows user display name from dashboard context',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _discoverScreenOverrides(withAuth: true),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: orgThemed(
              child: const Scaffold(
                body: OrganizationDiscoverScreen(
                  from: OrgDiscoverEntryContext.dashboard,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You are browsing as Test User'), findsOneWidget);
      expect(
        find.byKey(const Key('org_discover_browse_as_banner')),
        findsOneWidget,
      );
    },
  );

  testWidgets('browse-as banner shows org name from org context', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _discoverScreenOverrides(
          orgs: [_dashboardOrg],
          withAuth: true,
        ),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(
            child: const Scaffold(
              body: OrganizationDiscoverScreen(
                from: OrgDiscoverEntryContext.org,
                orgId: 'org-home',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You are browsing as Home Shelter'), findsOneWidget);
  });

  testWidgets(
    'back from dashboard context goes to org dashboard when cannot pop',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/o/orgs/discover?from=dashboard',
        routes: [
          GoRoute(
            path: '/o/orgs',
            builder: (context, state) =>
                const Scaffold(body: Text('org-dashboard')),
          ),
          GoRoute(
            path: '/o/orgs/discover',
            builder: (context, state) => orgThemed(
              child: Scaffold(
                body: OrganizationDiscoverScreen(
                  from: parseOrgDiscoverEntryContext(
                    state.uri.queryParameters['from'],
                  ),
                  orgId: state.uri.queryParameters['orgId'],
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _discoverScreenOverrides(withAuth: true),
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('org_discover_back')));
      await tester.pumpAndSettle();

      expect(find.text('org-dashboard'), findsOneWidget);
    },
  );

  testWidgets('back from org context goes to org profile when cannot pop', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/o/orgs/discover?from=org&orgId=org-home',
      routes: [
        GoRoute(
          path: '/o/orgs/discover',
          builder: (context, state) => orgThemed(
            child: Scaffold(
              body: OrganizationDiscoverScreen(
                from: parseOrgDiscoverEntryContext(
                  state.uri.queryParameters['from'],
                ),
                orgId: state.uri.queryParameters['orgId'],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/o/orgs/:id',
          builder: (context, state) =>
              Scaffold(body: Text('profile:${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _discoverScreenOverrides(
          orgs: [_dashboardOrg],
          withAuth: true,
        ),
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('org_discover_back')));
    await tester.pumpAndSettle();

    expect(find.text('profile:org-home'), findsOneWidget);
  });
}
