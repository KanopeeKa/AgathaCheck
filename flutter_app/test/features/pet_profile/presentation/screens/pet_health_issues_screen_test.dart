import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_issue.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_issue_document.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_issue_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/screens/pet_health_issues_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _FakeHealthIssueNotifier extends HealthIssueNotifier {
  _FakeHealthIssueNotifier(this._issues);

  final List<HealthIssue> _issues;

  @override
  Future<List<HealthIssue>> build(String arg) async => _issues;
}

class _FailingHealthIssueNotifier extends HealthIssueNotifier {
  @override
  Future<List<HealthIssue>> build(String arg) async {
    throw Exception('network');
  }
}

Future<List<HealthIssueDocument>> _emptyDocuments(ref, String issueId) async =>
    [];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final issue = HealthIssue(
    id: 'issue-1',
    petId: 'pet-1',
    title: 'Skin allergy',
    description: 'Itchy paws during summer months.',
    startDate: DateTime(2025, 6, 1),
  );

  Widget buildApp({required List<HealthIssue> issues}) {
    final router = GoRouter(
      initialLocation: '/pet/pet-1/health-issues',
      routes: [
        GoRoute(
          path: '/pet/:petId/health-issues',
          builder: (context, state) =>
              PetHealthIssuesScreen(petId: state.pathParameters['petId']!),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        // removed resolvedExperienceProvider mock
        experienceEligibilityProvider.overrideWith(
          (ref) => AsyncValue.data(
            ExperienceEligibilityRules.compute(
              pets: const [],
              orgMembershipCount: 0,
            ),
          ),
        ),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
        orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
        apiBaseUrlProvider.overrideWithValue('http://test.local'),
        healthIssueNotifierProvider.overrideWith(
          () => _FakeHealthIssueNotifier(issues),
        ),
        healthIssueDocumentsProvider.overrideWith(_emptyDocuments),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('shows title, add action, and issue list', (tester) async {
    await tester.pumpWidget(buildApp(issues: [issue]));
    await tester.pumpAndSettle();

    expect(find.text('Health Issues'), findsOneWidget);
    expect(find.byKey(const Key('health_issues_add_app_bar')), findsOneWidget);
    expect(find.text('Skin allergy'), findsOneWidget);
  });

  testWidgets('shows empty state with add action', (tester) async {
    await tester.pumpWidget(buildApp(issues: const []));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('health_issues_empty')), findsOneWidget);
    expect(find.text('No health issues yet'), findsOneWidget);
    expect(find.byKey(const Key('health_issues_empty_add')), findsOneWidget);

    await tester.tap(find.byKey(const Key('health_issues_empty_add')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('load error shows retry without exception text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(
              ExperienceEligibilityRules.compute(
                pets: const [],
                orgMembershipCount: 0,
              ),
            ),
          ),
          combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
          guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
          orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          healthIssueNotifierProvider.overrideWith(
            _FailingHealthIssueNotifier.new,
          ),
          healthIssueDocumentsProvider.overrideWith(_emptyDocuments),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: '/pet/pet-1/health-issues',
            routes: [
              GoRoute(
                path: '/pet/:petId/health-issues',
                builder: (context, state) => PetHealthIssuesScreen(
                  petId: state.pathParameters['petId']!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Exception'), findsNothing);
    expect(find.text('We couldn\'t load health issues'), findsOneWidget);
    expect(find.byKey(const Key('health_issues_load_retry')), findsOneWidget);
  });

  testWidgets('expands and collapses an issue card', (tester) async {
    await tester.pumpWidget(buildApp(issues: [issue]));
    await tester.pumpAndSettle();

    expect(find.text('Status'), findsNothing);

    await tester.tap(find.byKey(const Key('health_issue_header_issue-1')));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('health_issue_header_issue-1')));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsNothing);
  });
}
