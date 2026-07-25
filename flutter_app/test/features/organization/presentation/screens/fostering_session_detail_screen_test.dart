import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_session_status.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_provider_pets.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/fostering_session/fostering_session_detail_screen.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/pet_foster_placement_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets(
    'session detail shows preparation checklist and transition action',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            organizationRepositoryProvider.overrideWithValue(
              _PreparationSessionRepo(),
            ),
            isOrgAdminProvider('org-1').overrideWith((ref) => true),
            isOrgFosterProvider('org-1').overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: FosteringSessionDetailScreen(
                orgId: 'org-1',
                placementId: 'placement-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fostering_session_detail_body')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fostering_session_preparation_checklist')),
        findsOneWidget,
      );
      expect(find.text('Preparation'), findsOneWidget);
      expect(
        find.byKey(const Key('fostering_session_mark_ready')),
        findsOneWidget,
      );
    },
  );

  testWidgets('placement section links to fostering session when open', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: PetFosterPlacementSection(
              orgId: 'org-1',
              petId: 'pet-1',
              petName: 'Max',
            ),
          ),
        ),
        GoRoute(
          path: '/o/orgs/:orgId/placements/:placementId/session',
          builder: (context, state) =>
              const Scaffold(body: Text('Session detail route')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _OpenSessionPlacementRepo(),
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
    await tester.tap(find.text('Foster placement'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_fostering_session_button')));
    await tester.pumpAndSettle();

    expect(find.text('Session detail route'), findsOneWidget);
  });
}

class _PreparationSessionRepo extends RecordingOrganizationRepository {
  @override
  Future<FosterPlacement> getPlacementDetail(
    String orgId,
    String placementId,
    String token,
  ) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'pending',
    sessionStatus: FosterSessionStatus.preparation,
    petName: 'Max',
    fosterName: 'Jane Foster',
  );
}

class _OpenSessionPlacementRepo extends RecordingOrganizationRepository {
  @override
  Future<PetFosterPlacementState> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) async {
    final placement = FosterPlacement(
      id: 'placement-1',
      organizationId: orgId,
      petId: petId,
      fosterUserId: 'user-1',
      status: 'pending',
      sessionStatus: FosterSessionStatus.preparation,
      petName: 'Max',
      fosterName: 'Jane Foster',
    );
    return PetFosterPlacementState(
      status: placement.status,
      placement: placement,
    );
  }
}
