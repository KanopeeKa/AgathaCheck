import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_provider_invites.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organization_list_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _OrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'org-1',
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
    ),
  ];
}

class _EmptyPendingInvitesNotifier extends PendingOrgInvitesNotifier {
  @override
  Future<List<PendingOrgInvite>> build() async => [];
}

void main() {
  testWidgets('org list uses organization light background and create CTA', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/o/orgs',
      routes: [
        GoRoute(
          path: '/o/orgs',
          builder: (context, state) => const OrganizationListScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationListProvider.overrideWith(_OrgListNotifier.new),
          pendingOrgInvitesProvider.overrideWith(
            _EmptyPendingInvitesNotifier.new,
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(
      find.ancestor(
        of: find.byKey(const Key('org_create_button')),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, AppColorTokens.organizationLight);

    expect(find.byKey(const Key('org_create_button')), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Rescue Hearts'), findsOneWidget);
  });
}
