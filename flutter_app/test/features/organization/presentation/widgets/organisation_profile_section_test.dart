import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_permissions_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_profile/organisation_profile_member_sections.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_profile/organisation_profile_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

const _orgId = 'org-1';

Future<void> _pumpSection(
  WidgetTester tester, {
  required Set<String> permissions,
  required Widget child,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        organizationRepositoryProvider.overrideWithValue(
          RecordingOrganizationRepository(),
        ),
        orgEffectivePermissionsProvider(
          _orgId,
        ).overrideWith((ref) async => permissions),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OrganisationProfileSection', () {
    testWidgets('renders title and preview when permission granted', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_admin_contacts'},
        child: OrganisationProfileSection(
          orgId: _orgId,
          permissionKey: 'view_admin_contacts',
          sectionKey: const Key('org_profile_section_admin_contacts'),
          title: 'Admin contacts',
          preview: const Text('Preview body'),
        ),
      );

      expect(
        find.byKey(const Key('org_profile_section_admin_contacts')),
        findsOneWidget,
      );
      expect(find.text('Admin contacts'), findsOneWidget);
      expect(find.text('Preview body'), findsOneWidget);
    });

    testWidgets('hides section when permission missing', (tester) async {
      await _pumpSection(
        tester,
        permissions: const {},
        child: OrganisationProfileSection(
          orgId: _orgId,
          permissionKey: 'view_admin_contacts',
          sectionKey: const Key('org_profile_section_admin_contacts'),
          title: 'Admin contacts',
          preview: const Text('Preview body'),
        ),
      );

      expect(
        find.byKey(const Key('org_profile_section_admin_contacts')),
        findsNothing,
      );
      expect(find.text('Admin contacts'), findsNothing);
    });

    testWidgets('shows manage link only when manage permission granted', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_org_internal', 'manage_fosters'},
        child: OrganisationProfileSection(
          orgId: _orgId,
          permissionKey: 'view_org_internal',
          title: 'Fosters',
          preview: const Text('Foster preview'),
          manageLinkLabel: 'Manage fosters',
          managePermissionKey: 'manage_fosters',
          onManage: () {},
        ),
      );

      expect(find.text('Manage fosters'), findsOneWidget);
    });

    testWidgets('hides manage link when manage permission missing', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_org_internal'},
        child: OrganisationProfileSection(
          orgId: _orgId,
          permissionKey: 'view_org_internal',
          title: 'Fosters',
          preview: const Text('Foster preview'),
          manageLinkLabel: 'Manage fosters',
          managePermissionKey: 'manage_fosters',
          onManage: () {},
        ),
      );

      expect(find.text('Manage fosters'), findsNothing);
    });
  });

  group('OrganisationProfileMemberSections gate combinations', () {
    testWidgets('shows only admin contacts when that view key is granted', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_admin_contacts'},
        child: const OrganisationProfileMemberSections(orgId: _orgId),
      );

      expect(
        find.byKey(const Key('org_profile_section_admin_contacts')),
        findsOneWidget,
      );
      expect(find.text('Admin contacts'), findsWidgets);
      expect(
        find.byKey(const Key('org_profile_section_fosters')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('org_profile_section_fostering_sessions')),
        findsNothing,
      );
      expect(find.byKey(const Key('org_profile_section_pets')), findsNothing);
      expect(
        find.byKey(const Key('org_profile_section_connections')),
        findsNothing,
      );
    });

    testWidgets(
      'shows fosters section without manage link for view-only member',
      (tester) async {
        await _pumpSection(
          tester,
          permissions: {'view_org_internal'},
          child: const OrganisationProfileMemberSections(orgId: _orgId),
        );

        expect(
          find.byKey(const Key('org_profile_section_fosters')),
          findsOneWidget,
        );
        expect(find.text('Foster parents'), findsOneWidget);
        expect(find.text('Manage fosters'), findsNothing);
      },
    );

    testWidgets('shows fosters manage link when manage_fosters is granted', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_org_internal', 'manage_fosters'},
        child: const OrganisationProfileMemberSections(orgId: _orgId),
      );

      expect(
        find.byKey(const Key('org_profile_section_fosters')),
        findsOneWidget,
      );
      expect(find.text('Manage fosters'), findsOneWidget);
    });

    testWidgets('shows fostering sessions only for view_fostering_sessions', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_fostering_sessions'},
        child: const OrganisationProfileMemberSections(orgId: _orgId),
      );

      expect(
        find.byKey(const Key('org_profile_section_fostering_sessions')),
        findsOneWidget,
      );
      expect(find.text('Fostering sessions'), findsOneWidget);
      expect(find.byKey(const Key('org_profile_section_pets')), findsNothing);
    });

    testWidgets('shows pets and connections for associate-style view keys', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_org_pets', 'view_connections'},
        child: const OrganisationProfileMemberSections(orgId: _orgId),
      );

      expect(find.byKey(const Key('org_profile_section_pets')), findsOneWidget);
      expect(
        find.byKey(const Key('org_profile_section_connections')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('org_profile_section_fosters')),
        findsNothing,
      );
    });

    testWidgets('shows connections manage link when manage_members granted', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_connections', 'manage_members'},
        child: const OrganisationProfileMemberSections(orgId: _orgId),
      );

      expect(
        find.byKey(const Key('org_profile_section_connections')),
        findsOneWidget,
      );
      expect(find.text('Manage members'), findsOneWidget);
    });

    testWidgets('hides connections manage link without manage_members', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {'view_connections'},
        child: const OrganisationProfileMemberSections(orgId: _orgId),
      );

      expect(find.text('Manage members'), findsNothing);
    });

    testWidgets('shows all member sections when all view keys are granted', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        permissions: {
          'view_admin_contacts',
          'view_org_internal',
          'view_fostering_sessions',
          'view_org_pets',
          'view_connections',
          'manage_fosters',
          'manage_members',
        },
        child: const OrganisationProfileMemberSections(orgId: _orgId),
      );

      expect(
        find.byKey(const Key('org_profile_section_admin_contacts')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('org_profile_section_fosters')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('org_profile_section_fostering_sessions')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('org_profile_section_pets')), findsOneWidget);
      expect(
        find.byKey(const Key('org_profile_section_connections')),
        findsOneWidget,
      );
      expect(find.text('Manage fosters'), findsOneWidget);
      expect(find.text('Manage members'), findsOneWidget);
    });
  });
}
