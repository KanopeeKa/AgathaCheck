import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';
import '../../l10n/app_localizations.dart';
import '../../features/experience/presentation/screens/account_screen.dart';
import '../../features/experience/presentation/screens/experience_chooser_screen.dart';
import '../../features/experience/presentation/screens/experience_home_screens.dart';
import '../../features/experience/presentation/screens/experience_resolve_screen.dart';
import '../../features/experience/presentation/screens/experience_settings_screen.dart';
import '../../features/experience/presentation/screens/pet_care_onboarding_screen.dart';
import '../../features/experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../features/experience/presentation/screens/pet_care/pet_care_all_pets_screen.dart';
import '../../features/experience/presentation/screens/pet_care/pet_care_bulk_share_select_screen.dart';
import '../../features/experience/presentation/screens/pet_care/add_event_type_picker_sheet.dart';
import '../../features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart';
import '../../features/pet_profile/domain/entities/pet.dart';
import '../../features/pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../features/pet_profile/presentation/providers/pet_providers.dart';

/// Maps legacy `/g/*` paths to `/pc/*` equivalents.
String? legacyPetCareRedirectForPath(String path) {
  if (path == '/g' || path.startsWith('/g/')) {
    return '/pc${path.substring(2)}';
  }
  return null;
}

List<RouteBase> buildExperienceRoutes() {
  return [
    GoRoute(
      path: '/app/resolve',
      name: 'experienceResolve',
      builder: (context, state) => const ExperienceResolveScreen(),
    ),
    GoRoute(
      path: '/app/choose',
      name: 'experienceChoose',
      builder: (context, state) => const ExperienceChooserScreen(),
    ),
    GoRoute(
      path: '/pc/onboarding',
      name: 'petCareOnboarding',
      builder: (context, state) => const PetCareOnboardingScreen(),
    ),
    GoRoute(
      path: '/g/onboarding',
      name: 'guardianOnboarding',
      redirect: (context, state) =>
          legacyPetCareRedirectForPath(state.uri.path),
    ),
    GoRoute(
      path: '/o/onboarding',
      redirect: (context, state) => '/pc/home',
    ),
    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) => const AccountScreen(),
      routes: [
        GoRoute(
          path: 'orgs/:orgId',
          redirect: (context, state) => '/account',
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          path: '/pc/home',
          name: 'petCareHome',
          builder: (context, state) => const PetCareHomeScreen(),
        ),
        GoRoute(
          path: '/pc/pets',
          name: 'petCareAllPets',
          builder: (context, state) => const PetCareAllPetsScreen(),
          routes: [
            GoRoute(
              path: 'bulk-share',
              name: 'petCareBulkSharePets',
              builder: (context, state) => const PetCareBulkShareSelectScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/pc/events',
          name: 'petCareEvents',
          builder: (context, state) => const _PetCareEventsScreen(),
        ),
        GoRoute(
          path: '/pc/fostering',
          redirect: (context, state) => '/pc/home',
        ),
        GoRoute(
          path: '/pc/invite',
          name: 'petCareInvite',
          builder: (context, state) =>
              const ExperienceInviteScreen(experience: AppExperience.petCare),
        ),
        GoRoute(
          path: '/pc/settings',
          name: 'petCareSettings',
          redirect: (context, state) => '/account',
        ),
        GoRoute(
          path: '/pc/notifications',
          name: 'petCareNotifications',
          redirect: (context, state) => '/pc/home',
        ),
        GoRoute(
          path: '/g/home',
          name: 'guardianHome',
          redirect: (context, state) =>
              legacyPetCareRedirectForPath(state.uri.path),
        ),
        GoRoute(
          path: '/g/pets',
          name: 'guardianAllPets',
          redirect: (context, state) =>
              legacyPetCareRedirectForPath(state.uri.path),
        ),
        GoRoute(
          path: '/g/pets/bulk-share',
          name: 'guardianBulkSharePets',
          redirect: (context, state) =>
              legacyPetCareRedirectForPath(state.uri.path),
        ),
        GoRoute(
          path: '/g/events',
          name: 'guardianEvents',
          redirect: (context, state) =>
              legacyPetCareRedirectForPath(state.uri.path),
        ),
        GoRoute(
          path: '/g/fostering',
          redirect: (context, state) => '/pc/home',
        ),
        GoRoute(
          path: '/g/invite',
          name: 'guardianInvite',
          redirect: (context, state) =>
              legacyPetCareRedirectForPath(state.uri.path),
        ),
        GoRoute(
          path: '/g/settings',
          name: 'guardianSettings',
          redirect: (context, state) => '/account',
        ),
        GoRoute(
          path: '/g/notifications',
          name: 'guardianNotifications',
          redirect: (context, state) => '/pc/home',
        ),
      ],
    ),
  ];
}

class _PetCareEventsScreen extends ConsumerWidget {
  const _PetCareEventsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);
    final allPets = petsAsync.valueOrNull ?? const <Pet>[];
    final shellPets = PetListController().guardianShellPets(allPets);
    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.eventsNavLabel,
      backPath: '/pc/home',
      contextualActions: [
        IconButton(
          key: const Key('global_events_add_app_bar'),
          tooltip: l.addAnEvent,
          icon: const Icon(Icons.add),
          onPressed: petsAsync.hasValue
              ? () => showAddEventTypePickerSheet(context, pets: shellPets)
              : null,
        ),
      ],
      child: const PetCareDueEventsScreen(),
    );
  }
}
