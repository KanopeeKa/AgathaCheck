import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/archived_pet.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organization_pets_screen.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_pets_care_utils.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';
import '../../../helpers/organization_provider_test_helpers.dart';

class _OrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [
    Organization(
      id: 'org-1',
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
      role: 'admin',
    ),
  ];
}

class _OrgPetsScreenRepo extends RecordingOrganizationRepository {
  @override
  Future<List<Map<String, dynamic>>> getOrganizationPets(
    String orgId,
    String token,
  ) async {
    return [
      {'id': 'pet-max', 'name': 'Max', 'species': 'Dog', 'passed_away': false},
    ];
  }

  @override
  Future<List<FosterPlacement>> getOrganizationPlacements(
    String orgId,
    String token, {
    Map<String, String>? filters,
  }) async {
    return const [];
  }

  @override
  Future<List<ArchivedPet>> getOrganizationArchivedPets(
    String orgId,
    String token,
  ) async {
    return const [];
  }
}

void main() {
  testWidgets('Need attention tab shows pet with explanation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _OrgPetsScreenRepo(),
          ),
          orgPetsTabProvider(
            'org-1',
          ).overrideWith((ref) => OrgPetsTab.needAttention),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OrganizationPetsScreen(orgId: 'org-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Need attention'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Not in foster'), findsOneWidget);
  });

  testWidgets('Need attention info icon exposes tooltip message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _OrgPetsScreenRepo(),
          ),
          orgPetsTabProvider(
            'org-1',
          ).overrideWith((ref) => OrgPetsTab.needAttention),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OrganizationPetsScreen(orgId: 'org-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final tooltip = tester.widget<Tooltip>(
      find.byKey(const Key('org_pets_need_attention_tooltip')),
    );
    expect(
      tooltip.message,
      'Pets that are not in foster, or whose foster placement ends within 10 days with no next session or adoption planned.',
    );
  });

  testWidgets('top nav add pet when user can manage pets', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const OrganizationPetsScreen(orgId: 'org-1'),
        ),
        GoRoute(
          path: '/add',
          builder: (context, state) =>
              const Scaffold(body: Text('add-pet-route')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _OrgPetsScreenRepo(),
          ),
          organizationListProvider.overrideWith(_OrgListNotifier.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_add_pet_nav')), findsOneWidget);
    expect(find.byKey(const Key('org_add_pet_fab')), findsNothing);

    await tester.tap(find.byKey(const Key('org_add_pet_nav')));
    await tester.pumpAndSettle();

    expect(find.text('add-pet-route'), findsOneWidget);
  });

  testWidgets('filter chips toggle name search field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _OrgPetsScreenRepo(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OrganizationPetsScreen(orgId: 'org-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_pets_name_search')), findsNothing);

    await tester.tap(find.byKey(const Key('org_pets_filter_name')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_pets_name_search')), findsOneWidget);
  });
}
