import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_connection.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_profile/organisation_profile_admin_contacts.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_profile/organisation_profile_connections.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

class _PeopleRepo extends RecordingOrganizationRepository {
  _PeopleRepo(this._people);

  final List<OrgPersonSummary> _people;

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async =>
      _people;
}

class _ConnectionsRepo extends RecordingOrganizationRepository {
  _ConnectionsRepo(this._connections);

  final List<OrgConnection> _connections;

  @override
  Future<List<OrgConnection>> getConnections(
    String orgId,
    String token,
  ) async => _connections;
}

Future<void> _pumpWidget(
  WidgetTester tester, {
  required Widget child,
  required RecordingOrganizationRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        organizationRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OrganisationProfileAdminContacts', () {
    const people = [
      OrgPersonSummary(
        id: 'member:ou-a',
        kind: OrgPersonKind.member,
        recordId: 'ou-a',
        userId: 'user-a',
        displayName: 'Grace Admin',
        email: 'grace@example.com',
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

    testWidgets('shows admin contact cards with role labels', (tester) async {
      await _pumpWidget(
        tester,
        repo: _PeopleRepo(people),
        child: const OrganisationProfileAdminContacts(orgId: 'org-1'),
      );

      expect(find.text('Grace Admin'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Frank Foster'), findsNothing);
      expect(
        find.byKey(const Key('org_profile_admin_contact_ou-a')),
        findsOneWidget,
      );
    });

    testWidgets('hides message affordance until in-app messaging ships', (
      tester,
    ) async {
      await _pumpWidget(
        tester,
        repo: _PeopleRepo(people),
        child: const OrganisationProfileAdminContacts(orgId: 'org-1'),
      );

      expect(find.byKey(const Key('admin_contact_message_ou-a')), findsNothing);
      expect(find.text('Message'), findsNothing);
    });
  });

  group('OrganisationProfileConnections', () {
    const connections = [
      OrgConnection(
        id: 'conn-1',
        peerOrgId: 'org-2',
        peerOrgName: 'Partner Rescue',
        peerOrgEmail: 'partner@example.com',
      ),
    ];

    testWidgets('shows connected organisation tiles', (tester) async {
      await _pumpWidget(
        tester,
        repo: _ConnectionsRepo(connections),
        child: const OrganisationProfileConnections(orgId: 'org-1'),
      );

      expect(find.text('Partner Rescue'), findsOneWidget);
      expect(find.text('partner@example.com'), findsOneWidget);
      expect(
        find.byKey(const Key('org_profile_connection_org-2')),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when no connections', (tester) async {
      await _pumpWidget(
        tester,
        repo: _ConnectionsRepo([]),
        child: const OrganisationProfileConnections(orgId: 'org-1'),
      );

      expect(find.text('No connected organisations yet'), findsOneWidget);
    });
  });
}
