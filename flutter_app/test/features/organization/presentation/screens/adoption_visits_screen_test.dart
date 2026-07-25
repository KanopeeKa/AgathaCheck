import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_provider_pets.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/adoption_screening/adoption_visits_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets(
    'adoption visits screen shows visit_outcome and records outcome',
    (tester) async {
      final repo = _AdoptionVisitsRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            organizationRepositoryProvider.overrideWithValue(repo),
            isOrgAdminProvider('org-1').overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AdoptionVisitsScreen(orgId: 'org-1')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Outcome pending'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('adoption_visit_visit-1_positive')),
      );
      await tester.pumpAndSettle();

      expect(repo.recordOutcomeCalls, 1);
      expect(repo.lastOutcome, 'positive');
    },
  );
}

class _AdoptionVisitsRepo extends RecordingOrganizationRepository {
  var recordOutcomeCalls = 0;
  String? lastOutcome;

  @override
  Future<List<Map<String, dynamic>>> getAdoptionVisits(
    String orgId,
    String token,
  ) async => [
    {
      'id': 'visit-1',
      'scheduled_at': '2026-07-25T10:00:00Z',
      'status': 'scheduled',
      'visit_outcome': null,
    },
  ];

  @override
  Future<Map<String, dynamic>> recordAdoptionVisitOutcome(
    String orgId,
    String visitId,
    String visitOutcome,
    String token,
  ) async {
    recordOutcomeCalls++;
    lastOutcome = visitOutcome;
    return {'id': visitId, 'visit_outcome': visitOutcome};
  }
}
