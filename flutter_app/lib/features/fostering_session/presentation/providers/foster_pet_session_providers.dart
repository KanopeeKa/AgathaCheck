import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../organization/domain/entities/foster_placement.dart';
import '../../../organization/presentation/providers/foster_placements_providers.dart';
import '../../../pet_profile/presentation/providers/pet_timeline_providers.dart';

/// Resolves the open fostering placement id for a foster carer's pet (v1: one open session).
final openFosterPlacementForPetProvider =
    FutureProvider.family<String?, String>((ref, petId) async {
      final pending = await ref.watch(pendingFosterPlacementsProvider.future);
      final pendingMatch = pending.where((p) => p.petId == petId).toList();
      if (pendingMatch.isNotEmpty) return pendingMatch.first.id;

      final adoptions = await ref.watch(
        pendingAdoptionPlacementsProvider.future,
      );
      final adoptionMatch = adoptions.where((p) => p.petId == petId).toList();
      if (adoptionMatch.isNotEmpty) return adoptionMatch.first.id;

      final segments = await ref.watch(petTimelineProvider(petId).future);
      final openSessions = segments
          .where(
            (s) =>
                s.isFosteringSession &&
                (s.endDate == null || s.endDate!.isEmpty),
          )
          .toList();
      if (openSessions.isEmpty) return null;
      return openSessions.last.id;
    });

final openFosterPlacementForPetStateProvider =
    FutureProvider.family<FosterPlacement?, String>((ref, petId) async {
      final placementId = await ref.watch(
        openFosterPlacementForPetProvider(petId).future,
      );
      if (placementId == null) return null;

      final pending = await ref.watch(pendingFosterPlacementsProvider.future);
      final pendingMatch = pending.where((p) => p.id == placementId);
      if (pendingMatch.isNotEmpty) return pendingMatch.first;

      final adoptions = await ref.watch(
        pendingAdoptionPlacementsProvider.future,
      );
      final adoptionMatch = adoptions.where((p) => p.id == placementId);
      if (adoptionMatch.isNotEmpty) return adoptionMatch.first;

      return FosterPlacement(
        id: placementId,
        organizationId: '',
        petId: petId,
        fosterUserId: '',
        status: 'in_progress',
        sessionStatus: 'active',
      );
    });
