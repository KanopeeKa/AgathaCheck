import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_screen_theme.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_discover_nav_row.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('discover nav row navigates to discover screen', (tester) async {
    final router = GoRouter(
      initialLocation: '/o/orgs',
      routes: [
        GoRoute(
          path: '/o/orgs',
          builder: (context, state) => orgThemed(
            child: const Scaffold(body: OrgDiscoverNavRow()),
          ),
        ),
        GoRoute(
          path: '/o/orgs/discover',
          builder: (context, state) =>
              const Scaffold(body: Text('discover-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_discover_nav_row')), findsOneWidget);
    expect(find.text('Discover Organisations'), findsOneWidget);

    await tester.tap(find.byKey(const Key('org_discover_nav_row')));
    await tester.pumpAndSettle();

    expect(find.text('discover-screen'), findsOneWidget);
  });
}
