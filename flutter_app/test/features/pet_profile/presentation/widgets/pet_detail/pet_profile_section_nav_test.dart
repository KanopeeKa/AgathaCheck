import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_profile_section_nav.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildNav({required GoRouter router}) {
    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('shows timeline, weight, and health issues nav rows', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pet/pet-1',
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => Scaffold(
            body: PetProfileSectionNav(petId: state.pathParameters['petId']!),
          ),
        ),
        GoRoute(
          path: '/pet/:petId/timeline',
          builder: (context, state) => const Scaffold(body: Text('Timeline')),
        ),
        GoRoute(
          path: '/pet/:petId/weight',
          builder: (context, state) => const Scaffold(body: Text('Weight')),
        ),
        GoRoute(
          path: '/pet/:petId/health-issues',
          builder: (context, state) =>
              const Scaffold(body: Text('Health issues')),
        ),
      ],
    );

    await tester.pumpWidget(buildNav(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Weight Tracking'), findsOneWidget);
    expect(find.text('Health Issues'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('timeline row navigates to dedicated route', (tester) async {
    final router = GoRouter(
      initialLocation: '/pet/pet-1',
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => Scaffold(
            body: PetProfileSectionNav(petId: state.pathParameters['petId']!),
          ),
        ),
        GoRoute(
          path: '/pet/:petId/timeline',
          builder: (context, state) =>
              const Scaffold(body: Text('Timeline screen')),
        ),
      ],
    );

    await tester.pumpWidget(buildNav(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pet_profile_nav_timeline')));
    await tester.pumpAndSettle();

    expect(find.text('Timeline screen'), findsOneWidget);
  });
}
