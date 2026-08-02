import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organisation_profile_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

class _EmptyOrgsNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [];
}

class _PublicProfileRepo extends RecordingOrganizationRepository {
  @override
  Future<Organization> getPublicOrganization(
    String id, {
    String? token,
  }) async => Organization(
    id: id,
    name: 'Rescue Hearts',
    type: OrganizationType.charity,
    description: 'A caring rescue shelter',
    town: 'Springfield',
    administrativeArea: 'IL',
  );
}

void main() {
  Future<void> pumpProfileScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/o/orgs/org-1',
      routes: [
        GoRoute(
          path: '/o/orgs',
          builder: (context, state) =>
              const Scaffold(body: Text('org list')),
        ),
        GoRoute(
          path: '/o/orgs/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganisationProfileScreen(orgId: id);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationListProvider.overrideWith(_EmptyOrgsNotifier.new),
          organizationRepositoryProvider.overrideWithValue(_PublicProfileRepo()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows organisation name in profile header', (tester) async {
    await pumpProfileScreen(tester);

    expect(find.byKey(const Key('org_profile_screen')), findsOneWidget);
    expect(find.text('Rescue Hearts'), findsWidgets);
    expect(find.text('A caring rescue shelter'), findsOneWidget);
  });
}
