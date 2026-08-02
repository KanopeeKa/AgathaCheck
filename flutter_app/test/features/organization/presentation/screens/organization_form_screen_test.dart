import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organization_form_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _EditOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'org-1',
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
      address: '123 Main St',
      town: 'Springfield',
      administrativeArea: 'IL',
      publicProfileMetadata: {'postcode': '62701'},
    ),
  ];
}

void main() {
  Future<void> pumpForm(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/o/orgs/org-1/edit',
      routes: [
        GoRoute(
          path: '/o/orgs/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganizationFormScreen(orgId: id);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationListProvider.overrideWith(_EditOrgListNotifier.new),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('edit form shows structured address and image guidance', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(find.byKey(const Key('org_form_screen')), findsOneWidget);
    expect(find.byKey(const Key('org_town_field')), findsOneWidget);
    expect(find.byKey(const Key('org_administrative_area_field')), findsOneWidget);
    expect(find.byKey(const Key('org_postcode_field')), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('org_postcode_field'))).controller?.text,
      '62701',
    );
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('org_town_field'))).controller?.text,
      'Springfield',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('org_administrative_area_field')))
          .controller
          ?.text,
      'IL',
    );
    expect(find.byKey(const Key('org_upload_logo_button')), findsOneWidget);
    expect(find.byKey(const Key('org_upload_picture_button')), findsOneWidget);
    expect(find.textContaining('1200×450'), findsOneWidget);
    expect(find.textContaining('256×256'), findsOneWidget);
  });
}
