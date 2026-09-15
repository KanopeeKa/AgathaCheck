import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/away_planning_dashboard_tile_state.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/widgets/planned_absence_entry_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildTile(Future<AwayPlanningDashboardTileState> future) {
    return ProviderScope(
      overrides: [
        awayPlanningDashboardTileProvider.overrideWith((ref) => future),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const PlannedAbsenceEntryTile(),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('shows prompt tile', (tester) async {
    await tester.pumpWidget(
      buildTile(Future.value(AwayPlanningDashboardTileState.prompt)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('planned_absence_entry_tile')), findsOneWidget);
  });

  testWidgets('degrades to prompt while loading', (tester) async {
    await tester.pumpWidget(
      buildTile(Completer<AwayPlanningDashboardTileState>().future),
    );
    await tester.pump();

    expect(find.byKey(const Key('planned_absence_entry_tile')), findsOneWidget);
  });

  testWidgets('shows stateful copy for upcoming absence', (tester) async {
    const absence = PlannedAbsence(
      id: 'abs-1',
      userId: 'user-1',
      startsOn: '2026-10-01',
      endsOn: '2026-10-05',
      provenance: 'user_declared',
      status: 'active',
      petIds: const ['pet-1'],
    );
    final state = AwayPlanningDashboardTileState.stateful(
      absence: absence,
      tileCopy: const AwayPlanTileCopy(
        source: 'carer_coverage',
        copyKey: 'awayPlanningTileCarerNone',
      ),
    );

    await tester.pumpWidget(buildTile(Future.value(state)));
    await tester.pumpAndSettle();

    expect(find.text('Choose who will care for your pets.'), findsOneWidget);
  });
}
