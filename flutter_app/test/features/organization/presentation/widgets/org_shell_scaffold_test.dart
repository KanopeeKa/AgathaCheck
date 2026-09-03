import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_workspace_toggle.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_shell_scaffold.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('OrgShellScaffold shows workspace toggle on deep org routes', (
    tester,
  ) async {
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

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_shell_workspace_toggle')), findsOneWidget);
    expect(find.byType(ExperienceWorkspaceToggle), findsOneWidget);
  });

  testWidgets('OrgShellScaffold shows back and workspace toggle together', (
    tester,
  ) async {
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

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('org_shell_back')), findsOneWidget);
    expect(find.byKey(const Key('org_shell_workspace_toggle')), findsOneWidget);
  });
}
