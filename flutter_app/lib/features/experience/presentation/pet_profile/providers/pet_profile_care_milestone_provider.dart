import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

final petProfileCareMilestoneProvider =
    Provider.family<AsyncValue<CarePendingMoment?>, String>((ref, petId) {
      final safeguardAsync = ref.watch(petProfileCareSafeguardProvider(petId));
      final suggestionAsync = ref.watch(
        petProfileCareSuggestionProvider(petId),
      );
      final momentsAsync = ref.watch(petPendingCareMomentsProvider(petId));

      if (momentsAsync.isLoading ||
          safeguardAsync.isLoading ||
          suggestionAsync.isLoading) {
        return const AsyncLoading();
      }
      if (momentsAsync.hasError) {
        return AsyncError(
          momentsAsync.error!,
          momentsAsync.stackTrace ?? StackTrace.empty,
        );
      }

      if (safeguardAsync.valueOrNull != null ||
          suggestionAsync.valueOrNull != null) {
        return const AsyncData(null);
      }

      final moment = momentsAsync.valueOrNull?.moments.firstOrNull;
      return AsyncData(moment);
    });
