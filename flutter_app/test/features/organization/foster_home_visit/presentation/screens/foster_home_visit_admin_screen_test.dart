import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/foster_home_visit/domain/entities/foster_home_visit.dart';
import 'package:pet_profile_app/features/organization/foster_home_visit/presentation/providers/foster_home_visit_providers.dart';
import 'package:pet_profile_app/features/organization/foster_home_visit/presentation/screens/foster_home_visit_admin_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';
import '../../helpers/fake_foster_home_visit_repository.dart';

void main() {
  testWidgets('admin screen shows schedule form when no active visit', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          fosterHomeVisitRepositoryProvider.overrideWithValue(
            FakeFosterHomeVisitRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FosterHomeVisitAdminScreen(
              orgId: 'org-1',
              fosterParentId: 'fp-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Schedule home visit'), findsOneWidget);
    expect(find.byKey(const Key('foster_home_visit_schedule_submit')), findsOneWidget);
    expect(find.text('No previous home visits recorded.'), findsOneWidget);
  });

  testWidgets('admin screen shows validate form for scheduled visit', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          fosterHomeVisitRepositoryProvider.overrideWithValue(
            FakeFosterHomeVisitRepository(
              visits: const [
                FosterHomeVisit(
                  id: 'hv-1',
                  organizationId: 'org-1',
                  orgFosterParentId: 'fp-1',
                  status: FosterHomeVisitStatus.scheduled,
                  visitDate: '2026-10-01',
                  visitTime: '11:00',
                  address: '123 Foster Lane',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FosterHomeVisitAdminScreen(
              orgId: 'org-1',
              fosterParentId: 'fp-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Scheduled visit'), findsOneWidget);
    expect(find.textContaining('01/10/2026'), findsOneWidget);
    expect(find.text('Visit address: 123 Foster Lane'), findsOneWidget);
    expect(find.byKey(const Key('foster_home_visit_validate_submit')), findsOneWidget);
    expect(find.byKey(const Key('foster_home_visit_cancel_button')), findsOneWidget);
  });
}
