import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_onboarding_step.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/foster_onboarding_timeline.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  final timeline = FosterOnboardingStatus(
    resourceId: 'fp-1',
    steps: const [
      FosterOnboardingStep(key: 'connected', label: 'Connected', state: FosterOnboardingStepState.complete),
      FosterOnboardingStep(key: 'profile', label: 'Profile', state: FosterOnboardingStepState.complete),
      FosterOnboardingStep(key: 'onboarding_form', label: 'Form', state: FosterOnboardingStepState.current, deferred: true),
    ],
  );

  testWidgets('renders title, deferred copy, and disc states', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        organizationRepositoryProvider.overrideWithValue(RecordingOrganizationRepository()),
        organizationListProvider.overrideWith(() => _AdminOrgListNotifier()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FosterOnboardingTimeline(orgId: 'org-1', kind: 'external', recordId: 'fp-1', timeline: timeline)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Foster onboarding status'), findsOneWidget);
    expect(find.text('Not recorded yet'), findsOneWidget);
    expect(find.byKey(const Key('foster_onboarding_disc_complete')), findsNWidgets(2));
    expect(find.byKey(const Key('foster_onboarding_disc_current')), findsOneWidget);
  });

  testWidgets('shows confirm on incomplete steps for admins', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        organizationRepositoryProvider.overrideWithValue(RecordingOrganizationRepository()),
        organizationListProvider.overrideWith(() => _AdminOrgListNotifier()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FosterOnboardingTimeline(orgId: 'org-1', kind: 'external', recordId: 'fp-1', timeline: timeline)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('foster_onboarding_confirm_onboarding_form')), findsOneWidget);
    expect(find.byKey(const Key('foster_onboarding_confirm_connected')), findsNothing);
  });
}

class _AdminOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(id: 'org-1', name: 'Shelter', type: OrganizationType.charity, role: 'super_admin'),
  ];
}
