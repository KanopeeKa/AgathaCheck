import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organisation_profile_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

class _MemberOrgsNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'org-1',
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
      description: 'A caring rescue shelter',
      role: 'super_admin',
    ),
  ];
}

class _PublicProfileRepo extends RecordingOrganizationRepository {
  @override
  Future<Organization> getPublicOrganization(
    String id, {
    String? token,
  }) async => Organization(
    id: id,
    name: 'Rescue Hearts',
    type: OrganizationType.charity,
    description: 'A caring rescue shelter',
    town: 'Springfield',
    administrativeArea: 'IL',
  );
}

void main() {
  Future<void> pumpProfileScreen(
    WidgetTester tester, {
    Set<String> permissions = const {'manage_permissions', 'manage_members'},
  }) async {
    final router = GoRouter(
      initialLocation: '/o/orgs/org-1',
      routes: [
        GoRoute(
          path: '/o/orgs',
          builder: (context, state) => const Scaffold(body: Text('org list')),
        ),
        GoRoute(
          path: '/o/orgs/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganisationProfileScreen(orgId: id);
          },
        ),
        GoRoute(
          path: '/o/orgs/:id/edit',
          builder: (context, state) =>
              const Scaffold(body: Text('edit screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationListProvider.overrideWith(_MemberOrgsNotifier.new),
          organizationRepositoryProvider.overrideWithValue(
            _PublicProfileRepo(),
          ),
          orgEffectivePermissionsProvider(
            'org-1',
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

  testWidgets('shows organisation name in profile header', (tester) async {
    await pumpProfileScreen(tester);

    expect(find.byKey(const Key('org_profile_screen')), findsOneWidget);
    expect(find.byKey(const Key('org_hero_name')), findsOneWidget);
    expect(find.text('Rescue Hearts'), findsWidgets);
    expect(find.text('A caring rescue shelter'), findsOneWidget);
  });

  testWidgets('manage_permissions user sees edit icon not settings cog', (
    tester,
  ) async {
    await pumpProfileScreen(tester);

    expect(find.byKey(const Key('org_profile_edit')), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.byKey(const Key('org_profile_settings')), findsNothing);
  });

  testWidgets('profile menu shows invite and members but not delete', (
    tester,
  ) async {
    await pumpProfileScreen(tester);

    await tester.tap(find.byKey(const Key('org_profile_menu')));
    await tester.pumpAndSettle();

    expect(find.text('Invite Member'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Leave Organization'), findsOneWidget);
    expect(find.text('Delete Organization'), findsNothing);
  });

  testWidgets('edit icon navigates to edit route', (tester) async {
    await pumpProfileScreen(tester);

    await tester.tap(find.byKey(const Key('org_profile_edit')));
    await tester.pumpAndSettle();

    expect(find.text('edit screen'), findsOneWidget);
  });
}
