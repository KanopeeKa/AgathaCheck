import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/admin_contacts_screen.dart';
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
  }) async {
    final router = GoRouter(
      initialLocation: '/o/orgs/org-1/admin-contacts',
      routes: [
        GoRoute(
          path: '/o/orgs/:id/admin-contacts',
          builder: (context, state) =>
              AdminContactsScreen(orgId: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationListProvider.overrideWith(() => _OrgListNotifier(role)),
          organizationRepositoryProvider.overrideWithValue(
            _AdminContactsPeopleRepo(people),
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

  testWidgets(
    'admin contacts screen pins self-card first then sorts by last name',
    (tester) async {
      await pumpScreen(tester);

      expect(find.text('Admin contacts'), findsOneWidget);
      expect(find.text('Your card'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);

      final names = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .whereType<String>()
          .where((t) => t.contains('Admin') || t == 'Test User')
          .toList();

      expect(names.first, 'Test User');
      expect(
        names.indexOf('Anna Admin'),
        lessThan(names.indexOf('Zara Admin')),
      );
      expect(find.text('Frank Foster'), findsNothing);
    },
  );

  testWidgets('super admin sees add admin affordance', (tester) async {
    await pumpScreen(tester, role: 'super_admin');

    expect(find.byKey(const Key('admin_contacts_add')), findsOneWidget);
    expect(find.byKey(const Key('admin_contacts_add_button')), findsOneWidget);
  });

  testWidgets('foster member does not see add admin affordance', (
    tester,
  ) async {
    await pumpScreen(tester, role: 'foster');

    expect(find.byKey(const Key('admin_contacts_add')), findsNothing);
    expect(find.byKey(const Key('admin_contacts_add_button')), findsNothing);
  });

  testWidgets('self-card no longer shows local visibility editors', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('admin_contact_phone_visibility')), findsNothing);
    expect(find.byKey(const Key('admin_contact_message_channel')), findsNothing);
  });
}

class _AdminContactsPeopleRepo extends RecordingOrganizationRepository {
  _AdminContactsPeopleRepo(this._people);

  final List<OrgPersonSummary> _people;

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async =>
      _people;
}
