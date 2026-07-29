import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pet_profile/presentation/providers/pet_providers.dart';
import '../../features/weight_tracking/presentation/providers/weight_providers.dart';

/// Refreshes weight-entry history for one pet (safe from inside [PetListNotifier]).
void invalidateWeightEntryProviders(Ref ref, String petId) {
  ref.invalidate(weightEntriesNotifierProvider(petId));
  ref.invalidate(latestWeightProvider(petId));
}

/// Refreshes weight history and pet list caches after weight-only mutations.
void invalidatePetWeightData(Ref ref, String petId) {
  invalidateWeightEntryProviders(ref, petId);
  ref.invalidate(petListProvider);
  ref.invalidate(allPetsIncludingOrgProvider);
}
