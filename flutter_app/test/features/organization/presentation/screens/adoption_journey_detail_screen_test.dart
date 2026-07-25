import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/adoption_journey/adoption_journey_detail_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets('adoption journey detail shows milestone checklist', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _AdoptionJourneyRepo(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AdoptionJourneyDetailScreen(
              orgId: 'org-1',
              placementId: 'placement-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Adoption milestones'), findsOneWidget);
    expect(
      find.byKey(const Key('adoption_milestone_item_adoption_contract_prepared')),
      findsOneWidget,
    );
    expect(find.text('awaiting_foster_confirmation'), findsOneWidget);
  });
}

class _AdoptionJourneyRepo extends RecordingOrganizationRepository {
  @override
  Future<Map<String, dynamic>> getAdoptionJourney(
    String orgId,
    String placementId,
    String token,
  ) async => {
    'adoption_journey': {
      'status': 'awaiting_foster_confirmation',
      'adoption_conditions': 'Neuter within 30 days',
    },
  };

  @override
  Future<Map<String, dynamic>> getAdoptionMilestones(
    String orgId,
    String placementId,
    String token,
  ) async => {
    'journey_id': 'journey-1',
    'items': [
      {
        'key': 'adoption_contract_prepared',
        'label': 'Adoption contract prepared',
        'completed': false,
      },
    ],
  };
}
