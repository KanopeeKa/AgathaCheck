import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/care_recommendations_provider.dart';
import 'care_safeguard_card.dart';

/// Profile safeguard surface (max one card; beats suggestions).
class PetProfileCareSafeguardSection extends ConsumerWidget {
  const PetProfileCareSafeguardSection({
    super.key,
    required this.petId,
    required this.petName,
  });

  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeguardAsync = ref.watch(petProfileCareSafeguardProvider(petId));

    return safeguardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (safeguard) {
        if (safeguard == null) return const SizedBox.shrink();
        return CareSafeguardCard(
          petId: petId,
          petName: petName,
          safeguard: safeguard,
        );
      },
    );
  }
}
