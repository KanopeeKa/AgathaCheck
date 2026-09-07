import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/care_recommendation.dart';
import '../providers/care_recommendations_provider.dart';
import 'care_suggestion_card.dart';

/// Profile suggestion surface respecting presentation policy (max one card).
class PetProfileCareSuggestionSection extends ConsumerWidget {
  const PetProfileCareSuggestionSection({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(petProfileCareSuggestionProvider(petId));

    return suggestionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recommendation) {
        if (recommendation == null) return const SizedBox.shrink();
        return CareSuggestionCard(
          petId: petId,
          recommendation: recommendation,
        );
      },
    );
  }
}
