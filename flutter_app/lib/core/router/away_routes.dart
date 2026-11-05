import 'package:go_router/go_router.dart';

import '../../features/pet_care/pet_care.dart';

List<RouteBase> buildAwayPlanningRoutes() {
  return [
    GoRoute(
      path: '/pc/away',
      name: 'petCarePlannedAbsence',
      builder: (context, state) => const PlannedAbsenceHubScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'petCarePlannedAbsenceNew',
          builder: (context, state) => const PlannedAbsenceFlowScreen(),
        ),
        GoRoute(
          path: ':id',
          name: 'petCarePlannedAbsenceDetail',
          builder: (context, state) {
            final absenceId = state.pathParameters['id']!;
            return PlannedAbsencePlanScreen(absenceId: absenceId);
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'petCarePlannedAbsenceEdit',
              builder: (context, state) {
                final absenceId = state.pathParameters['id']!;
                return PlannedAbsenceEditScreen(absenceId: absenceId);
              },
            ),
            GoRoute(
              path: 'pets/:petId',
              name: 'petCarePetAwayPlan',
              builder: (context, state) {
                final absenceId = state.pathParameters['id']!;
                final petId = state.pathParameters['petId']!;
                return PetAwayPlanScreen(absenceId: absenceId, petId: petId);
              },
            ),
          ],
        ),
      ],
    ),
  ];
}
