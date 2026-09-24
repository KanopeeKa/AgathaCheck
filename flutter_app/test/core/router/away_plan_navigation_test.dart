import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/widgets/away_plan_pet_care_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

CarePeriodCoverageResult _coverage({
  required List<PlannedCareItem> plannedCareItems,
}) {
  return CarePeriodCoverageResult(
    startsOn: '2026-10-01',
    endsOn: '2026-10-05',
    projectionStatus: CarePeriodProjectionStatus.complete,
    items: const [],
    plannedCareItems: plannedCareItems,
    coverage: const CarePeriodCoverageSummary(
      policyVersion: '1',
      coverageState: CarePeriodCoverageState.hasItemsToReview,
      reasonCodes: [],
      reassuranceAvailable: true,
    ),
  );
}

class _BackScreen extends StatelessWidget {
  const _BackScreen({
    required this.label,
    this.backPath,
    this.returnTo,
    this.child,
  });

  final String label;
  final String? backPath;
  final String? returnTo;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(label, key: Key('screen_$label')),
          IconButton(
            key: Key('back_$label'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => handleShellBack(
              context,
              backPath: backPath,
              returnTo: returnTo,
              defaultPath: '/pc/home',
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('away plan navigation stack', () {
    testWidgets('home → plan → care item → back → back reaches home', (
      tester,
    ) async {
      const pet = Pet(
        id: 'pet-1',
        name: 'Luna',
        species: 'dog',
        breed: 'Mixed',
      );

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            petByIdProvider('pet-1').overrideWith((ref) async => pet),
            carePeriodCoverageProvider((
              petId: 'pet-1',
              startsOn: '2026-10-01',
              endsOn: '2026-10-05',
            )).overrideWith(
              (ref) async => _coverage(
                plannedCareItems: [
                  PlannedCareItem(
                    kind: PlannedCareKind.singleOnce,
                    healthEntryId: 'once-1',
                    name: 'Vet visit',
                    scheduledDate: '2026-10-03',
                  ),
                ],
              ),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router = GoRouter(
              initialLocation: '/pc/home',
              routes: [
                GoRoute(
                  path: '/pc/home',
                  builder: (context, __) => _BackScreen(
                    label: 'home',
                    child: FilledButton(
                      key: const Key('open_plan'),
                      onPressed: () => context.push('/pc/away/abs-1'),
                      child: const Text('Open plan'),
                    ),
                  ),
                ),
                GoRoute(
                  path: '/pc/away',
                  builder: (_, __) =>
                      const _BackScreen(label: 'hub', backPath: '/pc/home'),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => _BackScreen(
                        label: 'plan-${state.pathParameters['id']}',
                        backPath: '/pc/away',
                        child: AwayPlanPetCareSection(
                          absenceId: 'abs-1',
                          petId: 'pet-1',
                          petName: 'Luna',
                          startsOn: '2026-10-01',
                          endsOn: '2026-10-05',
                          onRetry: () {},
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: '/pet/:petId/events/:entryId',
                  builder: (_, state) {
                    final returnTo = shellReturnToFromState(state);
                    return _BackScreen(
                      label: 'event-${state.pathParameters['entryId']}',
                      returnTo: returnTo,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('screen_home')), findsOneWidget);

      await tester.tap(find.byKey(const Key('open_plan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen_plan-abs-1')), findsOneWidget);

      await tester.tap(find.text('Vet visit'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen_event-once-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('back_event-once-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen_plan-abs-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('back_plan-abs-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen_home')), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/pc/home');
    });
  });
}
