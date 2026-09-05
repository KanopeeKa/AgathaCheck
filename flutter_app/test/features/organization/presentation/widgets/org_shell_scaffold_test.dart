import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_shell_scaffold.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
  Widget _wrap(Widget child, {Size viewport = const Size(390, 844)}) {
    final router = GoRouter(
      initialLocation: '/o/orgs/org-1/pets',
      routes: [
        GoRoute(
          path: '/o/orgs/:id/pets',
          builder: (context, state) => OrgShellScaffold(
            title: 'Pets',
            orgId: state.pathParameters['id'],
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [authProvider.overrideWith((ref) => FakeAuthNotifier())],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(size: viewport),
          child: child!,
        ),
      ),
    );
  }

  testWidgets('OrgShellScaffold shows back on deep org routes', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_shell_back')), findsOneWidget);
  });

  testWidgets('OrgShellScaffold keeps Shelter bottom nav on deep org routes', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shelter_bottom_navigation')), findsOneWidget);
  });

  testWidgets('OrgShellScaffold keeps Shelter sidebar at expanded width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const SizedBox.shrink(), viewport: const Size(1024, 800)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shelter_navigation_sidebar')), findsOneWidget);
    expect(find.byKey(const Key('shelter_bottom_navigation')), findsNothing);
  });
}
