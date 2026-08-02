import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_permissions_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_provider_deps.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_profile/organisation_profile_member_sections.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_profile/organisation_profile_pets.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

const _orgId = 'org-1';

class _PetSummaryRepo extends RecordingOrganizationRepository {
  _PetSummaryRepo(this.summaryPets);

  final List<Map<String, dynamic>> summaryPets;

  @override
  Future<List<Map<String, dynamic>>> getOrganizationPetSummary(
    String orgId,
    String token,
  ) async => summaryPets;
}

Future<void> _pumpWithRouter(
  WidgetTester tester, {
  required Set<String> permissions,
  required Widget child,
  List<Map<String, dynamic>> summaryPets = const [],
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/o/orgs/:id/pets/:petId/redacted',
        builder: (context, state) =>
            const Scaffold(body: Text('redacted-route')),
      ),
      GoRoute(
        path: '/pet/:id',
        builder: (context, state) =>
            const Scaffold(body: Text('full-pet-route')),
      ),
      GoRoute(
        path: '/o/orgs/:id/pets',
        builder: (context, state) =>
            const Scaffold(body: Text('manage-pets-route')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        organizationRepositoryProvider.overrideWithValue(
          _PetSummaryRepo(summaryPets),
        ),
        orgEffectivePermissionsProvider(
          _orgId,
        ).overrideWith((ref) async => permissions),
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

void main() {
  group('OrganisationProfilePets', () {
    testWidgets('shows up to 12 pet tiles from summary API', (tester) async {
      await _pumpWithRouter(
        tester,
        permissions: {'view_org_pets'},
        summaryPets: [
          for (var i = 0; i < 12; i++)
            {
              'id': 'pet-$i',
              'name': 'Pet $i',
              'species': 'dog',
              'breed': 'Mix',
              'organization_id': _orgId,
            },
        ],
        child: const OrganisationProfilePets(orgId: _orgId),
      );

      expect(find.byKey(const Key('org_profile_pets_strip')), findsOneWidget);
      expect(find.byType(PetCard), findsNWidgets(12));
    });

    testWidgets('shows empty state when no pets', (tester) async {
      await _pumpWithRouter(
        tester,
        permissions: {'view_org_pets'},
        child: const OrganisationProfilePets(orgId: _orgId),
      );

      expect(find.text('No pets in this organization'), findsOneWidget);
    });

    testWidgets('associate tap opens redacted route', (tester) async {
      await _pumpWithRouter(
        tester,
        permissions: {'view_org_pets'},
        summaryPets: [
          {
            'id': 'pet-1',
            'name': 'Buddy',
            'species': 'dog',
            'breed': 'Labrador',
            'organization_id': _orgId,
          },
        ],
        child: const OrganisationProfilePets(orgId: _orgId),
      );

      await tester.tap(find.byType(PetCard));
      await tester.pumpAndSettle();

      expect(find.text('redacted-route'), findsOneWidget);
    });

    testWidgets('manage_pets tap opens full pet route', (tester) async {
      await _pumpWithRouter(
        tester,
        permissions: {'view_org_pets', 'manage_pets'},
        summaryPets: [
          {
            'id': 'pet-1',
            'name': 'Buddy',
            'species': 'dog',
            'breed': 'Labrador',
            'organization_id': _orgId,
          },
        ],
        child: const OrganisationProfilePets(orgId: _orgId),
      );

      await tester.tap(find.byType(PetCard));
      await tester.pumpAndSettle();

      expect(find.text('full-pet-route'), findsOneWidget);
    });
  });

  group('OrganisationProfileMemberSections pets integration', () {
    testWidgets('shows manage pets link when manage_pets granted', (
      tester,
    ) async {
      await _pumpWithRouter(
        tester,
        permissions: {'view_org_pets', 'manage_pets'},
        child: const OrganisationProfileMemberSections(orgId: _orgId),
      );

      expect(find.byKey(const Key('org_profile_section_pets')), findsOneWidget);
      expect(find.text('Manage pets'), findsOneWidget);
    });
  });
}
