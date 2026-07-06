import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/organization_people_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets('people section shows members and add external foster button', (tester) async {
    const people = [
      OrgPersonSummary(
        id: 'member:ou-1',
        kind: OrgPersonKind.member,
        recordId: 'ou-1',
        userId: 'user-1',
        displayName: 'Jane Foster',
        email: 'jane@example.com',
        role: OrgMemberRole.foster,
        activeFosterCount: 1,
      ),
      OrgPersonSummary(
        id: 'external:fp-1',
        kind: OrgPersonKind.external,
        recordId: 'fp-1',
        displayName: 'Off-app Parent',
        email: 'off@example.com',
      ),
    ];

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final l = AppLocalizations.of(context)!;
            final theme = Theme.of(context);
            return Scaffold(
              body: OrganizationPeopleSection(
                orgId: 'org-1',
                theme: theme,
                colorScheme: theme.colorScheme,
                l: l,
                localizedRoleLabel: (_, __) => 'Foster',
                isSuperUser: true,
                isOrgAdmin: true,
              ),
            );
          },
        ),
        GoRoute(
          path: '/organizations/:orgId/people/:kind/:recordId',
          builder: (context, state) => Scaffold(
            body: Text('Person ${state.pathParameters['recordId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _PeopleRepo(people),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('People'), findsOneWidget);
    expect(find.text('Jane Foster'), findsOneWidget);
    expect(find.text('Off-app Parent'), findsOneWidget);
    expect(find.byKey(const Key('org_add_external_foster_button')), findsOneWidget);
    expect(find.byKey(const Key('org_add_user_button')), findsOneWidget);

    await tester.tap(find.text('Jane Foster'));
    await tester.pumpAndSettle();
    expect(find.text('Person ou-1'), findsOneWidget);
  });

  testWidgets('people section hides add user button for non-super users', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _PeopleRepo([
              OrgPersonSummary(
                id: 'member:ou-1',
                kind: OrgPersonKind.member,
                recordId: 'ou-1',
                displayName: 'Jane Foster',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              final theme = Theme.of(context);
              return OrganizationPeopleSection(
                orgId: 'org-1',
                theme: theme,
                colorScheme: theme.colorScheme,
                l: l,
                localizedRoleLabel: (_, __) => 'Foster',
                isSuperUser: false,
                isOrgAdmin: true,
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_add_external_foster_button')), findsOneWidget);
    expect(find.byKey(const Key('org_add_user_button')), findsNothing);
  });
}

class _PeopleRepo extends RecordingOrganizationRepository {
  _PeopleRepo(this._people);

  final List<OrgPersonSummary> _people;

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async =>
      _people;
}
