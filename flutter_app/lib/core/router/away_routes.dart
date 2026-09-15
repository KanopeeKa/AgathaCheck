import 'package:go_router/go_router.dart';

import '../../features/pet_care/context/presentation/screens/planned_absence_flow_screen.dart';
import '../../features/pet_care/context/presentation/screens/planned_absence_hub_screen.dart';
import '../../features/pet_care/context/presentation/screens/planned_absence_plan_screen.dart';

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
        ),
      ],
    ),
  ];
}
