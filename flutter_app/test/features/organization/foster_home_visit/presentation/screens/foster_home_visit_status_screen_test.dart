import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/foster_home_visit/domain/entities/foster_home_visit.dart';
import 'package:pet_profile_app/features/organization/foster_home_visit/presentation/providers/foster_home_visit_providers.dart';
import 'package:pet_profile_app/features/organization/foster_home_visit/presentation/screens/foster_home_visit_status_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';
import '../../helpers/fake_foster_home_visit_repository.dart';

void main() {
  testWidgets('status screen shows active visit without address', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          fosterHomeVisitRepositoryProvider.overrideWithValue(
            FakeFosterHomeVisitRepository(
              status: const FosterHomeVisitStatusSnapshot(
                activeVisit: FosterHomeVisit(
                  id: 'hv-1',
                  organizationId: 'org-1',
                  orgFosterParentId: 'fp-1',
                  status: FosterHomeVisitStatus.scheduled,
                  visitDate: '2026-10-01',
                  visitTime: '11:00',
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FosterHomeVisitStatusScreen(
              orgId: 'org-1',
              fosterParentId: 'fp-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Scheduled visit'), findsOneWidget);
    expect(find.textContaining('01/10/2026 · 11:00'), findsOneWidget);
    expect(find.textContaining('Visit address'), findsNothing);
  });

  testWidgets('status screen shows validated yes without address', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          fosterHomeVisitRepositoryProvider.overrideWithValue(
            FakeFosterHomeVisitRepository(
              status: const FosterHomeVisitStatusSnapshot(
                latestValidated: FosterHomeVisit(
                  id: 'hv-1',
                  organizationId: 'org-1',
                  orgFosterParentId: 'fp-1',
                  status: FosterHomeVisitStatus.validated,
                  visitDate: '2026-10-01',
                  visitTime: '11:00',
                  outcome: FosterHomeVisitOutcome.yes,
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FosterHomeVisitStatusScreen(
              orgId: 'org-1',
              fosterParentId: 'fp-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home visit approved'), findsOneWidget);
    expect(find.textContaining('Visit address'), findsNothing);
  });

  testWidgets('status screen shows empty state when no visits', (tester) async {
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
            body: FosterHomeVisitStatusScreen(
              orgId: 'org-1',
              fosterParentId: 'fp-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        'No home visit is scheduled yet. The shelter will contact you when a visit is arranged.',
      ),
      findsOneWidget,
    );
  });
}
