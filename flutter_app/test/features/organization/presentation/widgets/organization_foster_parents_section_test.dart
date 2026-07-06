import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/organization_foster_parents_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets('foster parents section shows members and add button', (tester) async {
    const parents = [
      FosterParent(
        id: 'ou-1',
        kind: FosterParentKind.member,
        userId: 'user-1',
        displayName: 'Jane Foster',
        email: 'jane@example.com',
        role: OrgMemberRole.foster,
        activePetCount: 2,
        activePets: const [
          FosterParentAssignedPet(
            petId: 'pet-a',
            petName: 'Max',
            status: 'in_progress',
          ),
        ],
      ),
      FosterParent(
        id: 'fp-1',
        kind: FosterParentKind.external,
        displayName: 'Off-app Parent',
        email: 'off@example.com',
        activePetCount: 0,
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
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              final theme = Theme.of(context);
              return OrganizationFosterParentsSection(
                orgId: 'org-1',
                theme: theme,
                colorScheme: theme.colorScheme,
                l: l,
                localizedRoleLabel: (_, __) => 'Foster',
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Jane Foster'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Off-app Parent'), findsOneWidget);
    expect(find.byKey(const Key('org_add_foster_parent_button')), findsOneWidget);
  });
}

class _FosterParentsRepo extends RecordingOrganizationRepository {
  _FosterParentsRepo(this._parents);

  final List<FosterParent> _parents;

  @override
  Future<List<FosterParent>> getFosterParents(String orgId, String token) async =>
      _parents;
}
