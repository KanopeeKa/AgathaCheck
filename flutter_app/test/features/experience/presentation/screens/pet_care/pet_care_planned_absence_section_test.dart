import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/pet_care_planned_absence_section.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/away_planning_dashboard_tile_state.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('shows eyebrow, prompt tile, and all absences link', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const PetCarePlannedAbsenceSection(),
        ),
        GoRoute(
          path: '/pc/away',
          builder: (_, __) => const Scaffold(body: Text('away hub')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          awayPlanningDashboardTileProvider.overrideWith(
            (ref) async => AwayPlanningDashboardTileState.prompt,
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AWAY PLANNING'), findsOneWidget);
    expect(find.text("I'll be away"), findsOneWidget);
    expect(find.text('All absences'), findsOneWidget);

    await tester.tap(find.text('All absences'));
    await tester.pumpAndSettle();
    expect(find.text('away hub'), findsOneWidget);
  });
}
