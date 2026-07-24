import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/manage_fosters/manage_fosters_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';
import '../../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets('Manage Fosters screen shows tabs and foster cards', (tester) async {
    const parents = [
      FosterParent(
        id: 'fp-1',
        kind: FosterParentKind.member,
        userId: 'user-1',
        displayName: 'Eve Foster',
        email: 'eve@example.com',
        activePetCount: 1,
        activePets: [
          FosterParentAssignedPet(
            petId: 'pet-1',
            petName: 'Max',
            status: 'in_progress',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _FosterParentsRepo(parents),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ManageFostersScreen(orgId: 'org-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manage_fosters_tabs')), findsOneWidget);
    expect(find.text('Manage fosters'), findsOneWidget);
    expect(find.byKey(const Key('foster_summary_card_fp-1')), findsOneWidget);
    expect(find.text('Eve Foster'), findsOneWidget);
  });
}

class _FosterParentsRepo extends RecordingOrganizationRepository {
  _FosterParentsRepo(this._parents);

  final List<FosterParent> _parents;

  @override
  Future<List<FosterParent>> getFosterParents(String orgId, String token) async =>
      _parents;
}
