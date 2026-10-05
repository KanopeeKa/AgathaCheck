import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/pet_care_sync.dart';
import 'features/care_item/application/care_item_providers.dart';
import 'features/pet_profile/presentation/providers/pet_providers.dart';
import 'features/weight_tracking/presentation/providers/weight_providers.dart';

/// Composition-root [PetCareSync] (roadmap §6.1).
class AppPetCareSync implements PetCareSync {
  AppPetCareSync(this._ref);

  final Ref _ref;

  @override
  Future<void> weightChanged(String petId) async {
    _ref.invalidate(weightEntriesNotifierProvider(petId));
    _ref.invalidate(weightOverviewProvider(petId));
    _ref.invalidate(weightFulfilmentCandidatesProvider);
    _ref.invalidate(petListProvider);
    _ref.invalidate(allPetsIncludingOrgProvider);
  }

  @override
  Future<void> careChanged(String petId) async {
    await _ref.read(careDataChangedProvider)();
    _ref.invalidate(careItemsControllerProvider);
  }
}
