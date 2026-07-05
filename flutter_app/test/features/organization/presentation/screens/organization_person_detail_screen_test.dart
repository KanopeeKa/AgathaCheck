import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organization_person_detail_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../organization_providers_test.dart';

void main() {
  testWidgets('external foster detail shows contact info and placements', (tester) async {
    const detail = OrgPersonDetail(
      id: 'external:fp-1',
      kind: OrgPersonKind.external,
      recordId: 'fp-1',
      displayName: 'Off-app Parent',
      email: 'off@example.com',
      fosterPhone: '555-0000',
      fosterAddress: '1 Main St',
      adminNotes: 'Prefers cats',
      currentPlacements: [
        FosterPlacement(
          id: 'pl-1',
          organizationId: 'org-1',
          petId: 'pet-1',
          fosterUserId: '',
          status: 'in_progress',
          petName: 'Whiskers',
        ),
      ],
      pastPlacements: [
        OrgPersonPlacementPet(
          placement: FosterPlacement(
            id: 'pl-0',
            organizationId: 'org-1',
            petId: 'pet-0',
            fosterUserId: '',
            status: 'adopted',
            petName: 'Buddy',
          ),
          outcome: 'adopted',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _PersonDetailRepo(detail),
          ),
          organizationListProvider.overrideWith(() => _AdminOrgListNotifier()),
          isOrgAdminProvider.overrideWith((ref, orgId) => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OrganizationPersonDetailScreen(
            orgId: 'org-1',
            kind: 'external',
            recordId: 'fp-1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Off-app Parent'), findsWidgets);
    expect(find.text('off@example.com'), findsOneWidget);
    expect(find.text('555-0000'), findsOneWidget);
    expect(find.text('1 Main St'), findsOneWidget);
    expect(find.text('Prefers cats'), findsOneWidget);
    expect(find.text('Whiskers'), findsOneWidget);
    expect(find.text('Currently fostering'), findsOneWidget);
    expect(find.text('Edit foster contact'), findsOneWidget);
  });

  testWidgets('deleting external foster calls orgPeopleProvider.deleteExternal', (tester) async {
    final repo = _DeletablePersonDetailRepo();

    final router = GoRouter(
      initialLocation: '/home/person',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'person',
              builder: (context, state) => const OrganizationPersonDetailScreen(
                orgId: 'org-1',
                kind: 'external',
                recordId: 'fp-1',
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(repo),
          organizationListProvider.overrideWith(() => _AdminOrgListNotifier()),
          isOrgAdminProvider.overrideWith((ref, orgId) => true),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove foster parent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repo.deletedRecordIds, ['fp-1']);
    expect(find.text('Home'), findsOneWidget);
  });
}

class _PersonDetailRepo extends RecordingOrganizationRepository {
  _PersonDetailRepo(this._detail);

  final OrgPersonDetail _detail;

  @override
  Future<OrgPersonDetail> getPersonDetail(
    String orgId,
    OrgPersonKind kind,
    String recordId,
    String token,
  ) async =>
      _detail;
}

class _DeletablePersonDetailRepo extends RecordingOrganizationRepository {
  final deletedRecordIds = <String>[];

  @override
  Future<OrgPersonDetail> getPersonDetail(
    String orgId,
    OrgPersonKind kind,
    String recordId,
    String token,
  ) async =>
      const OrgPersonDetail(
        id: 'external:fp-1',
        kind: OrgPersonKind.external,
        recordId: 'fp-1',
        displayName: 'Off-app Parent',
        email: 'off@example.com',
      );

  @override
  Future<void> deleteExternalFosterParent(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    deletedRecordIds.add(fosterParentId);
  }
}

class _AdminOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
        Organization(
          id: 'org-1',
          name: 'Shelter',
          type: OrganizationType.charity,
          role: 'super_admin',
        ),
      ];
}
