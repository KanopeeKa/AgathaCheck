import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/organization/domain/entities/discoverable_organization.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_screen_theme.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_discovery/org_discovery_list.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_discovery/org_discovery_skeleton_list.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_discovery/org_discovery_tile.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_discovery_provider.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

const _sampleOrg = DiscoverableOrganization(
  id: 'org-discover-1',
  name: 'Rescue Hearts',
  type: OrganizationType.charity,
  logoUrl: '/uploads/org_photos/logo.jpg',
  photoUrl: '/uploads/org_photos/hero.jpg',
  displayLocality: '62701',
);

class _DiscoveryListNotifier extends OrgDiscoveryListNotifier {
  _DiscoveryListNotifier(this._items);

  final List<DiscoverableOrganization> _items;

  @override
  Future<List<DiscoverableOrganization>> build() async => _items;
}

class _LoadingDiscoveryNotifier extends OrgDiscoveryListNotifier {
  final _completer = Completer<List<DiscoverableOrganization>>();

  @override
  Future<List<DiscoverableOrganization>> build() => _completer.future;
}

void main() {
  testWidgets('discovery tile shows name and display_locality', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(
            child: Scaffold(
              body: SizedBox(
                width: 220,
                height: 220,
                child: OrgDiscoveryTile(organization: _sampleOrg),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rescue Hearts'), findsOneWidget);
    expect(find.text('62701'), findsOneWidget);
    expect(find.text('Charity'), findsOneWidget);
    expect(
      find.byKey(const Key('org_discovery_tile_org-discover-1')),
      findsOneWidget,
    );
  });

  testWidgets('tapping discovery tile navigates to organisation profile', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/o/orgs',
      routes: [
        GoRoute(
          path: '/o/orgs',
          builder: (context, state) => orgThemed(
            child: Scaffold(body: OrgDiscoveryTile(organization: _sampleOrg)),
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
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('org_discovery_tile_org-discover-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('profile:org-discover-1'), findsOneWidget);
  });

  testWidgets('discovery list shows skeleton while loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orgDiscoveryListProvider.overrideWith(_LoadingDiscoveryNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(child: const Scaffold(body: OrgDiscoveryList())),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('org_discovery_skeleton_list')),
      findsOneWidget,
    );
  });

  testWidgets('discovery list shows empty state when no organisations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orgDiscoveryListProvider.overrideWith(
            () => _DiscoveryListNotifier([]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(child: const Scaffold(body: OrgDiscoveryList())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_discovery_empty')), findsOneWidget);
    expect(find.text('No organisations to discover yet'), findsOneWidget);
  });

  testWidgets('discovery list renders result tiles', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orgDiscoveryListProvider.overrideWith(
            () => _DiscoveryListNotifier([_sampleOrg]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(child: const Scaffold(body: OrgDiscoveryList())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_discovery_results')), findsOneWidget);
    expect(
      find.byKey(const Key('org_discovery_tile_org-discover-1')),
      findsOneWidget,
    );
  });

  testWidgets('skeleton list renders placeholder cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: orgThemed(
          child: const Scaffold(body: OrgDiscoverySkeletonList()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('org_discovery_skeleton_list')),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNWidgets(2));
  });
}
