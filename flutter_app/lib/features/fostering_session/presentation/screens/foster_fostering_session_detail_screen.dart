import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../organization/presentation/providers/fostering_session_providers.dart';
import '../providers/foster_pet_session_providers.dart';
import '../widgets/session_detail_body.dart';

class FosterFosteringSessionDetailScreen extends ConsumerWidget {
  const FosterFosteringSessionDetailScreen({
    super.key,
    required this.petId,
    required this.placementId,
  });

  final String petId;
  final String placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final resolvedPlacementId = placementId.isNotEmpty
        ? placementId
        : ref.watch(openFosterPlacementForPetProvider(petId)).valueOrNull;

    if (resolvedPlacementId == null) {
      final resolving = ref.watch(openFosterPlacementForPetProvider(petId));
      return ExperienceShellScaffold(
        experience: AppExperience.petCare,
        currentLocation: GoRouterState.of(context).uri.path,
        screenTitle: l.fosteringSessionDetailTitle,
        backPath: '/pet/$petId',
        child: resolving.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (id) {
            if (id == null) {
              return Center(child: Text(l.fosterPlacementNotInFoster));
            }
            return FosterFosteringSessionDetailScreen(
              petId: petId,
              placementId: id,
            );
          },
        ),
      );
    }

    final key = (placementId: resolvedPlacementId, orgId: null);
    final sessionAsync = ref.watch(fosteringSessionDetailProvider(key));

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.fosteringSessionDetailTitle,
      backPath: '/pet/$petId',
      child: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (detail) => SessionDetailBody(
          orgId: detail.placement.organizationId,
          placementId: resolvedPlacementId,
          detail: detail,
        ),
      ),
    );
  }
}
