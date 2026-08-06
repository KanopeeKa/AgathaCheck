import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organization_people_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

class _OrgListNotifier extends OrganizationListNotifier {
  _OrgListNotifier(this.role);

  final String role;

  @override
  Future<List<Organization>> build() async => [
    Organization(
      id: 'org-1',
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
      role: role,
    ),
  ];
}

void main() {
  const people = [
    OrgPersonSummary(
      id: 'member:ou-z',
      kind: OrgPersonKind.member,
      recordId: 'ou-z',
      userId: 'user-z',
      displayName: 'Zara Admin',
      email: 'zara@example.com',
      role: OrgMemberRole.admin,
    ),
    OrgPersonSummary(
      id: 'member:ou-self',
      kind: OrgPersonKind.member,
      recordId: 'ou-self',
      userId: 'test-user-id',
      displayName: 'Test User',
      email: 'test@example.com',
      role: OrgMemberRole.superAdmin,
    ),
    OrgPersonSummary(
      id: 'member:ou-a',
      kind: OrgPersonKind.member,
      recordId: 'ou-a',
      userId: 'user-a',
      displayName: 'Anna Admin',
      email: 'anna@example.com',
      role: OrgMemberRole.admin,
    ),
    OrgPersonSummary(
      id: 'member:ou-f',
      kind: OrgPersonKind.member,
      recordId: 'ou-f',
      userId: 'user-f',
      displayName: 'Frank Foster',
      email: 'frank@example.com',
      role: OrgMemberRole.foster,
    ),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    String role = 'super_admin',
    String? filter,
  }) async {
    final location = filter == null
        ? '/o/orgs/org-1/people'
        : '/o/orgs/org-1/people?filter=$filter';
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/o/orgs/:id/people',
          builder: (context, state) => OrganizationPeopleScreen(
            orgId: state.pathParameters['id']!,
            filter: state.uri.queryParameters['filter'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationListProvider.overrideWith(() => _OrgListNotifier(role)),
          organizationRepositoryProvider.overrideWithValue(
            _OrgPeopleRepo(people),
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
  }

  group('OrganizationPeopleScreen — all people', () {
    testWidgets('lists everyone with self pinned first then alphabetical', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('People'), findsOneWidget);
      expect(find.byKey(const Key('org_people_tile_grid')), findsOneWidget);
      expect(find.text('Your card'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Frank Foster'), findsOneWidget);

      final names = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .whereType<String>()
          .where(
            (t) =>
                t.contains('Admin') ||
                t == 'Test User' ||
                t == 'Frank Foster',
          )
          .toList();

      expect(names.first, 'Test User');
      expect(
        names.indexOf('Anna Admin'),
        lessThan(names.indexOf('Zara Admin')),
      );
    });
  });

  group('OrganizationPeopleScreen — admins filter', () {
    testWidgets(
      'filter=admins shows only admins with self-card first then alphabetical',
      (tester) async {
        await pumpScreen(tester, filter: 'admins');

        expect(find.text('Admin contacts'), findsOneWidget);
        expect(
          find.byKey(const Key('admin_contacts_tile_grid')),
          findsOneWidget,
        );
        expect(find.text('Your card'), findsOneWidget);
        expect(find.text('Frank Foster'), findsNothing);
      },
    );

    testWidgets('super admin sees add admin affordance', (tester) async {
      await pumpScreen(tester, filter: 'admins', role: 'super_admin');

      expect(find.byKey(const Key('admin_contacts_add')), findsOneWidget);
    });

    testWidgets('foster member does not see add admin affordance', (
      tester,
    ) async {
      await pumpScreen(tester, filter: 'admins', role: 'foster');

      expect(find.byKey(const Key('admin_contacts_add')), findsNothing);
    });
  });
}

class _OrgPeopleRepo extends RecordingOrganizationRepository {
  _OrgPeopleRepo(this._people);

  final List<OrgPersonSummary> _people;

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async =>
      _people;
}
