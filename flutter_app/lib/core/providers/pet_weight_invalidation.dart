import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pet_profile/presentation/providers/pet_providers.dart';
import '../../features/weight_tracking/presentation/providers/weight_providers.dart';

/// Keeps pet profile weight and weight-entry history in sync after mutations.
void invalidatePetWeightData(Ref ref, String petId) {
  ref.invalidate(weightEntriesNotifierProvider(petId));
  ref.invalidate(latestWeightProvider(petId));
  ref.invalidate(petListProvider);
  ref.invalidate(allPetsIncludingOrgProvider);
}
