import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/core/widgets/async_state/async_state.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../domain/entities/app_experience.dart';
import '../../widgets/experience_shell_scaffold.dart';
import '../screens/pet_form_screen.dart';

/// Blocks deep links to `/edit/:id` when the user cannot edit the pet profile.
class PetEditPermissionGuard extends ConsumerWidget {
  const PetEditPermissionGuard({super.key, required this.petId, this.child});

  final String petId;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.path;
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);

    Widget shell({required Widget body, String? title}) {
      return ExperienceShellScaffold(
        experience: AppExperience.petCare,
        currentLocation: location,
        screenTitle: title ?? l.petDetails,
        child: body,
      );
    }

    if (petsAsync.isLoading) {
      return shell(
        body: const Center(child: CircularProgressIndicator()),
        title: l.petDetails,
      );
    }

    if (petsAsync.hasError) {
      return shell(
        body: AsyncErrorState(
          title: l.loadErrorYourPets,
          onRetry: () => ref.invalidate(allPetsIncludingOrgProvider),
          retryKey: const Key('pet_edit_guard_load_retry'),
        ),
      );
    }

    final pet = petsAsync.value?.where((p) => p.id == petId).firstOrNull;
    if (pet == null) {
      return shell(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AsyncErrorState(
              title: l.petNotFound,
              detail: null,
            ),
            TextButton(
              key: const Key('pet_edit_guard_back_to_pets'),
              onPressed: () => context.go('/pc/pets'),
              child: Text(l.backToPets),
            ),
          ],
        ),
      );
    }

    final viewerContext = ref.watch(petDetailViewerContextProvider(petId));
    if (!viewerContext.isPolicyResolved ||
        !viewerContext.can(PetDetailAction.editProfile)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) goToPetDetail(context, petId);
      });
      return shell(
        body: const Center(child: CircularProgressIndicator()),
        title: pet.name,
      );
    }

    return child ?? PetFormScreen(petId: petId);
  }
}
