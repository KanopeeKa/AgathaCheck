import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/core/widgets/async_state/async_state.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../widgets/all_care/all_care_list.dart';

/// Pet-scoped All care destination — unified temporal list of care items.
class PetManageEventsScreen extends ConsumerWidget {
  const PetManageEventsScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final experience = AppExperience.petCare;
    final location = GoRouterState.of(context).uri.path;

    Widget routeShell({
      required Widget child,
      String? screenTitle,
      List<Widget> contextualActions = const [],
    }) {
      return ExperienceShellScaffold(
        experience: experience,
        currentLocation: location,
        screenTitle: screenTitle ?? l.allCareTitle(''),
        backPath: petDetailBackPath(context, petId),
        contextualActions: contextualActions,
        child: child,
      );
    }

    return petsAsync.when(
      loading: () => routeShell(
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => routeShell(
        child: AsyncErrorState(
          title: l.loadErrorYourPets,
          onRetry: () => ref.invalidate(allPetsIncludingOrgProvider),
          retryKey: const Key('manage_events_pets_load_retry'),
        ),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == petId).firstOrNull;
        if (pet == null) {
          return routeShell(
            child: AsyncErrorState(title: l.petNotFound),
          );
        }

        return routeShell(
          screenTitle: l.allCareTitle(pet.name),
          contextualActions: [
            IconButton(
              key: const Key('manage_events_add_app_bar'),
              tooltip: l.addAnEvent,
              icon: const Icon(Icons.add),
              onPressed: () => navigateToAddHealthEntry(context, petId: petId),
            ),
          ],
          child: AllCareList(petId: petId),
        );
      },
    );
  }
}
