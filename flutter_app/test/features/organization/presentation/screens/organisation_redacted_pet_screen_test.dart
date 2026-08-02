import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_provider_deps.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organisation_redacted_pet_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

const _orgId = 'org-1';
const _petId = 'pet-1';

class _RedactedPetRepo extends RecordingOrganizationRepository {
  @override
  Future<Map<String, dynamic>> getRedactedOrganizationPet(
    String orgId,
    String petId,
    String token,
  ) async {
    return {
      'id': _petId,
      'name': 'Buddy',
      'species': 'Dog',
      'breed': 'Labrador',
      'date_of_birth': '2022-06-01',
      'organization_id': _orgId,
    };
  }
}

void main() {
  testWidgets('OrganisationRedactedPetScreen shows summary fields only', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(_RedactedPetRepo()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OrganisationRedactedPetScreen(orgId: _orgId, petId: _petId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_redacted_pet_screen')), findsOneWidget);
    expect(find.text('Buddy'), findsWidgets);
    expect(find.text('Labrador'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
  });
}
