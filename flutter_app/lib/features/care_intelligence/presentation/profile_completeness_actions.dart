import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import '../domain/profile_completeness_kind.dart';
import 'providers/profile_completeness_dismissal_provider.dart';

/// Dismiss / "not for my pet" for Agatha profile completeness cards (PR-04+).
class ProfileCompletenessActions {
  ProfileCompletenessActions(this.ref);

  final WidgetRef ref;

  Future<void> hidePrompt(Pet pet, ProfileCompletenessKind kind) async {
    final store = await ref.read(profileCompletenessDismissalStoreProvider.future);
    await store.recordDismiss(pet.id, kind);
    ref.invalidate(profileCompletenessDismissalStoreProvider);

    final updated = switch (kind) {
      ProfileCompletenessKind.neuter => pet.copyWith(neuterDismissed: true),
      ProfileCompletenessKind.chip => pet.copyWith(chipDismissed: true),
    };
    await ref.read(petListProvider.notifier).updatePet(updated);
  }
}
