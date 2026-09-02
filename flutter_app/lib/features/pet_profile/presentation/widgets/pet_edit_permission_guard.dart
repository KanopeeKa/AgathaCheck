import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';

import '../../domain/services/pet_detail_actions.dart';
import '../providers/pet_detail_viewer_context_provider.dart';
import '../providers/pet_providers.dart';
import '../screens/pet_form_screen.dart';

/// Blocks deep links to `/edit/:id` when the user cannot edit the pet profile.
class PetEditPermissionGuard extends ConsumerWidget {
  const PetEditPermissionGuard({super.key, required this.petId, this.child});

  final String petId;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);

    if (petsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pet = petsAsync.value?.where((p) => p.id == petId).firstOrNull;
    if (pet == null) {
      return const Scaffold(body: Center(child: Text('Pet not found')));
    }

    final viewerContext = ref.watch(petDetailViewerContextProvider(petId));
    if (!viewerContext.isPolicyResolved ||
        !viewerContext.can(PetDetailAction.editProfile)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) goToPetDetail(context, petId);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child ?? PetFormScreen(petId: petId);
  }
}
